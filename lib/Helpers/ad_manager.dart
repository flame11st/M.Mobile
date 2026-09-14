import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mmobile/Helpers/ad_inventory.dart';
import 'package:mmobile/Helpers/ad_policy.dart';
import 'package:mmobile/Helpers/google_ad_inventory_provider.dart';
import 'package:mmobile/Services/ad_privacy_consent.dart';
import 'package:mmobile/Services/monetization_config.dart';
import 'package:mmobile/Services/product_analytics.dart';

class AdManager {
  static final String _applicationSessionId = createProductAnalyticsId(
    'app-session',
  );
  static AdPolicyController _policy = AdPolicyController(
    sessionId: _applicationSessionId,
    config: const AdPolicyConfig(enabled: false),
  );
  static const _AdLifecycleObserver _lifecycleObserver = _AdLifecycleObserver(
    _handleLifecycleState,
  );

  static Future<InitializationStatus>? _mobileAdsInitialization;
  static InterstitialAd? _interstitial;
  static Timer? _exitObservationTimer;
  static bool _observerRegistered = false;
  static bool _premium = true;
  static bool _foreground = true;
  static bool _loadInFlight = false;
  static bool _showInFlight = false;
  static AdPlacement? _activePlacement;
  static _InterstitialAnalyticsAttempt? _analyticsAttempt;
  static _InterstitialAnalyticsAttempt? _lastClosedAttempt;
  static FocusNode? _focusBeforeInterstitial;
  static Future<void> _lastShowWrite = Future.value();
  static Future<void> _lastCloseWrite = Future.value();
  static AdInventoryCoordinator? _managedFormatInventory;
  static final Set<_ManagedNativePlacementInventory> _nativePlacements = {};
  static final Map<String, bool> _nativeInfrastructureByPlacement = {};
  static final AdPrivacyConsentController _privacy =
      AdPrivacyConsentController();
  static final ValueNotifier<AdPrivacySnapshot> _privacySnapshot =
      ValueNotifier<AdPrivacySnapshot>(_privacy.snapshot);

  static const String _androidNativeAdUnitId = String.fromEnvironment(
    'MOVIEDIARY_ANDROID_NATIVE_AD_UNIT_ID',
    defaultValue: MovieDiaryAdMobUnits.androidNative,
  );
  static const String _iosNativeAdUnitId = String.fromEnvironment(
    'MOVIEDIARY_IOS_NATIVE_AD_UNIT_ID',
    defaultValue: MovieDiaryAdMobUnits.iosNative,
  );
  static const String _androidRewardedAdUnitId = String.fromEnvironment(
    'MOVIEDIARY_ANDROID_REWARDED_AD_UNIT_ID',
    defaultValue: MovieDiaryAdMobUnits.androidRewarded,
  );
  static const String _iosRewardedAdUnitId = String.fromEnvironment(
    'MOVIEDIARY_IOS_REWARDED_AD_UNIT_ID',
    defaultValue: MovieDiaryAdMobUnits.iosRewarded,
  );

  static bool get interstitialInventoryEnabled => true;

  /// Provider-neutral native/rewarded lifecycle infrastructure.
  ///
  /// UXR69 intentionally exposes no product placement API. UXR70/UXR74 must
  /// separately connect an approved placement and explicitly enable this
  /// coordinator after policy evaluation.
  static AdInventoryCoordinator get managedFormatInventory =>
      _managedFormatInventory ??= AdInventoryCoordinator(
        provider: _managedFormatProvider,
      );

  static AdInventoryProvider get _managedFormatProvider {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const UnavailableAdInventoryProvider('unsupported_ad_platform');
    }

    final nativeAdUnitId = Platform.isAndroid
        ? _androidNativeAdUnitId
        : Platform.isIOS
        ? _iosNativeAdUnitId
        : '';
    final rewardedAdUnitId = Platform.isAndroid
        ? _androidRewardedAdUnitId
        : Platform.isIOS
        ? _iosRewardedAdUnitId
        : '';

    // Explicitly empty debug/profile overrides use Google's official sample
    // inventory. Normal builds use MovieDiary's production units; Google
    // automatically serves test creatives to registered test devices and
    // emulators. Release builds fail closed if an override removes a unit.
    if (!kReleaseMode && (nativeAdUnitId.isEmpty || rewardedAdUnitId.isEmpty)) {
      _diagnose('using Google Mobile Ads development inventory');
      return GoogleMobileAdsInventoryProvider.testInventory(
        requestFactory: _createAdRequest,
      );
    }

    if (nativeAdUnitId.isEmpty || rewardedAdUnitId.isEmpty) {
      return const UnavailableAdInventoryProvider(
        'managed_ad_units_not_configured',
      );
    }
    return GoogleMobileAdsInventoryProvider(
      nativeAdUnitId: nativeAdUnitId,
      rewardedAdUnitId: rewardedAdUnitId,
      requestFactory: _createAdRequest,
    );
  }

  static AdPrivacySnapshot get privacySnapshot => _privacy.snapshot;
  static ValueListenable<AdPrivacySnapshot> get privacySnapshotListenable =>
      _privacySnapshot;

  static Future<void> initializePrivacyForLaunch() async {
    _registerLifecycleObserver();
    final snapshot = await _privacy.initializeForLaunch();
    await _applyPrivacySnapshot(snapshot);
  }

  static Future<void> markMeaningfulProductExperience() =>
      _privacy.markMeaningfulProductExperience();

  static Future<AdPrivacyOptionsResult> showPrivacyOptions() async {
    final shown = await _privacy.showPrivacyOptions();
    await _applyPrivacySnapshot(_privacy.snapshot);
    return shown;
  }

  static Future<bool> ensureManagedFormatConsent() =>
      _ensureConsentForAdRequest();

  static Future<void> applyConfiguration(MonetizationConfig config) async {
    _registerLifecycleObserver();
    _policy = AdPolicyController(
      sessionId: _applicationSessionId,
      config: AdPolicyConfig(
        enabled: config.recommendationInterstitialPlacementEnabled,
        cooldown: Duration(minutes: config.interstitialMinIntervalMinutes),
        maxPerSession: config.interstitialMaxPerSession,
        maxPerDay: config.interstitialMaxPerDay,
        firstSessionEnabled: config.interstitialFirstSessionEnabled,
        firstDeckOfDayEnabled: config.interstitialFirstDeckOfDayEnabled,
      ),
    );
    await _policy.setPremium(_premium);
    _nativeInfrastructureByPlacement
      ..['discover_native'] = config.discoverNativePlacementEnabled
      ..['general_list_native'] = config.generalListNativePlacementEnabled
      ..['watchlist_native'] = config.myMoviesNativePlacementEnabled
      ..['viewed_native'] = config.myMoviesNativePlacementEnabled;
    await Future.wait(
      _nativePlacements.map(
        (placement) => placement.configure(
          infrastructureEnabled:
              _nativeInfrastructureByPlacement[placement.placement] ?? false,
          suppressed: _premium || !_privacy.snapshot.canRequestAds,
        ),
      ),
    );
    await managedFormatInventory.configure(
      infrastructureEnabled: config.extraRecommendationRewardedPlacementEnabled,
    );
    await managedFormatInventory.setSuppressed(
      _premium || !_privacy.snapshot.canRequestAds,
    );
    if (!config.recommendationInterstitialPlacementEnabled) {
      _activePlacement = null;
      await _disposeInterstitialInventory();
    }
  }

  static Future<void> setPremiumStatus(bool value) async {
    _premium = value;
    _registerLifecycleObserver();
    await _policy.setPremium(value);
    final privacySnapshot = await _privacy
        .refreshAfterLifecycleOrIdentityChange();
    await _applyPrivacySnapshot(privacySnapshot);
    await managedFormatInventory.setSuppressed(
      value || !_privacy.snapshot.canRequestAds,
    );
    await Future.wait(
      _nativePlacements.map(
        (placement) =>
            placement.setSuppressed(value || !_privacy.snapshot.canRequestAds),
      ),
    );

    if (value) {
      _activePlacement = null;
      _showInFlight = false;
      await _disposeInterstitialInventory();
      return;
    }

    await _emitRecoveredExitIfNeeded();
  }

  static Future<void> prepareRecommendationCompletionInterstitial() async {
    _registerLifecycleObserver();
    if (_premium || !interstitialInventoryEnabled) {
      return;
    }
    final shouldPreload = await _policy.shouldPreloadForNextCompletion(
      isPremium: _premium,
    );
    if (!shouldPreload || !await _ensureConsentForAdRequest()) {
      return;
    }
    await _prepareInventory();
  }

  static Future<void> recordMonetizationInteraction(
    MonetizationInteraction interaction,
  ) {
    return _policy.recordMonetizationInteraction(interaction);
  }

  static Future<void> recordDeckCompleted(
    AdPlacement placement, {
    required String completionId,
    required bool isPremium,
    String? recommendationSessionId,
    String? recommendationMode,
    String? mediaType,
  }) async {
    _premium = isPremium;
    _registerLifecycleObserver();
    final inventoryReady = _interstitial != null;
    final decision = await _policy.recordDeckCompleted(
      placement,
      completionId: completionId,
      isPremium: isPremium,
      isForeground: _foreground,
      consentGranted: _privacy.snapshot.canRequestAds,
      inventoryReady: inventoryReady,
    );

    final context = <ProductAnalyticsParameter, Object?>{
      ProductAnalyticsParameter.placement: placement.wireName,
      ProductAnalyticsParameter.adPlacement: placement.wireName,
      ProductAnalyticsParameter.isPremium: isPremium,
      ProductAnalyticsParameter.sourceSurface: 'recommendations',
      if (recommendationSessionId != null && recommendationSessionId.isNotEmpty)
        ProductAnalyticsParameter.recommendationSessionId:
            recommendationSessionId,
      if (recommendationMode != null && recommendationMode.isNotEmpty) ...{
        ProductAnalyticsParameter.recommendationMode: recommendationMode,
        ProductAnalyticsParameter.discoveryMode: recommendationMode,
      },
      if (mediaType != null && mediaType.isNotEmpty)
        ProductAnalyticsParameter.mediaType: mediaType,
      ProductAnalyticsParameter.deckNumberToday: decision.deckNumberToday,
      ProductAnalyticsParameter.interstitialCountSession:
          decision.shownCountSession,
      ProductAnalyticsParameter.interstitialCountDay: decision.shownCountDay,
      ProductAnalyticsParameter.outcomeCategory: decision.reason.wireName,
    };

    if (decision.isFrequencyCapped) {
      await ProductAnalytics.instance.track(
        ProductAnalyticsEventName.interstitialSkippedFrequencyCap,
        parameters: context,
        transitionId: '$completionId:interstitial-frequency-cap',
      );
    }

    if (decision.reason == AdPolicyDenialReason.inventoryNotReady ||
        decision.reason == AdPolicyDenialReason.consentUnavailable ||
        decision.reason == AdPolicyDenialReason.notForeground) {
      final attemptId = createProductAnalyticsId('monetization');
      await ProductAnalytics.instance.track(
        ProductAnalyticsEventName.interstitialSkippedNotLoaded,
        parameters: {
          ...context,
          ProductAnalyticsParameter.monetizationId: attemptId,
        },
        transitionId: '$completionId:interstitial-skipped-not-loaded',
      );
    }

    if (!decision.shouldAttempt) {
      return;
    }

    final attemptId = createProductAnalyticsId('monetization');
    final attempt = _InterstitialAnalyticsAttempt(
      id: attemptId,
      placement: placement,
      parameters: {
        ...context,
        ProductAnalyticsParameter.monetizationId: attemptId,
      },
    );
    _analyticsAttempt = attempt;
    await _trackAttempt(
      ProductAnalyticsEventName.interstitialEligible,
      attempt,
      suffix: 'eligible',
    );
    await _trackAttempt(
      ProductAnalyticsEventName.interstitialLoaded,
      attempt,
      suffix: 'loaded',
      additional: const {
        ProductAnalyticsParameter.outcomeCategory: 'preloaded',
      },
    );
    if (!await _tryShow()) {
      await _policy.cancelPending(placement);
      await _finishSkippedNotLoaded('boundary_revalidation_failed');
    }
  }

  static Future<void> _prepareInventory() async {
    if (_premium || !interstitialInventoryEnabled) {
      return;
    }

    final consentGranted = await _ensureConsentForAdRequest();
    if (!consentGranted || _premium) {
      if (!consentGranted) {
        await _trackFailure('consent', 'consent_unavailable');
        await _finishSkippedNotLoaded('consent_unavailable');
      }
      return;
    }

    if (_interstitial != null) {
      return;
    }
    if (_loadInFlight) {
      return;
    }

    _loadInFlight = true;
    try {
      _mobileAdsInitialization ??= MobileAds.instance.initialize();
      await _mobileAdsInitialization;
      if (_premium) {
        _loadInFlight = false;
        return;
      }

      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: _createAdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loadInFlight = false;
            if (_premium) {
              unawaited(ad.dispose());
              return;
            }
            _interstitial = ad;
            ad.onPaidEvent = _onPaidEvent;
            ad.fullScreenContentCallback = const FullScreenContentCallback(
              onAdShowedFullScreenContent: _onAdShown,
              onAdFailedToShowFullScreenContent: _onAdFailedToShow,
              onAdDismissedFullScreenContent: _onAdDismissed,
            );
          },
          onAdFailedToLoad: (error) {
            _loadInFlight = false;
            _diagnose('interstitial inventory unavailable: $error');
            unawaited(_handleLoadFailure());
          },
        ),
      );
    } catch (error) {
      _loadInFlight = false;
      _diagnose('interstitial preparation deferred: $error');
      await _trackFailure('load', 'exception');
      await _finishSkippedNotLoaded('load_exception');
    }
  }

  static Future<bool> _ensureConsentForAdRequest() async {
    final snapshot = await _privacy.ensureConsentForAdRequest();
    await _applyPrivacySnapshot(snapshot);
    if (!snapshot.canRequestAds) {
      _diagnose('ad privacy unavailable: ${snapshot.diagnosticCode}');
    }
    return snapshot.canRequestAds;
  }

  static Future<void> _applyPrivacySnapshot(AdPrivacySnapshot snapshot) async {
    _privacySnapshot.value = snapshot;
    final suppressed = _premium || !snapshot.canRequestAds;
    await managedFormatInventory.setSuppressed(suppressed);
    await Future.wait(
      _nativePlacements.map((placement) => placement.setSuppressed(suppressed)),
    );
    if (!snapshot.canRequestAds) {
      _activePlacement = null;
      _showInFlight = false;
      await _disposeInterstitialInventory();
    }
  }

  static AdRequest _createAdRequest() {
    return AdPrivacyAdRequestFactory.create(_privacy.snapshot);
  }

  static Future<bool> _tryShow() async {
    final inventory = _interstitial;
    if (inventory == null || _showInFlight) {
      return false;
    }
    if (!await _ensureConsentForAdRequest()) {
      return false;
    }

    final placement = _policy.pendingPlacement;
    final shouldShow = await _policy.shouldShowNow(
      isPremium: _premium,
      isForeground: _foreground,
      consentGranted: _privacy.snapshot.canRequestAds,
      inventoryReady: true,
    );
    if (!shouldShow || placement == null) {
      return false;
    }

    _showInFlight = true;
    _activePlacement = placement;
    _focusBeforeInterstitial = FocusManager.instance.primaryFocus;
    try {
      inventory.show();
      return true;
    } catch (error) {
      _showInFlight = false;
      _activePlacement = null;
      _interstitial = null;
      unawaited(inventory.dispose());
      _diagnose('interstitial show deferred: $error');
      await _trackFailure('show', 'exception');
      _finishAttempt();
      await _policy.cancelPending(placement);
      return false;
    }
  }

  static void _onAdShown(Ad ad) {
    _interstitial = null;
    _lastShowWrite = _handleAdShown();
    unawaited(_lastShowWrite);
  }

  static void _onAdFailedToShow(Ad ad, AdError error) {
    _showInFlight = false;
    _activePlacement = null;
    _interstitial = null;
    unawaited(ad.dispose());
    _restoreFocus();
    _diagnose('interstitial failed to show: $error');
    unawaited(_trackFailure('show', 'provider_callback'));
    final placement = _policy.pendingPlacement;
    if (placement != null) {
      unawaited(_policy.cancelPending(placement));
    }
    _finishAttempt();
  }

  static void _onAdDismissed(Ad ad) {
    final placement = _activePlacement;
    _showInFlight = false;
    _activePlacement = null;
    _interstitial = null;
    unawaited(ad.dispose());
    _restoreFocus();
    if (placement == null) {
      return;
    }

    unawaited(_handleAdDismissed(placement));
  }

  static void _handleLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    managedFormatInventory.setForeground(_foreground);
    if (_foreground) {
      _exitObservationTimer?.cancel();
      _exitObservationTimer = null;
      unawaited(_policy.markResumed());
      unawaited(() async {
        final snapshot = await _privacy.refreshAfterLifecycleOrIdentityChange();
        await _applyPrivacySnapshot(snapshot);
      }());
      return;
    }

    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    unawaited(
      _lastCloseWrite.then((_) => _policy.markBackgrounded()).then((candidate) {
        if (!candidate) {
          return;
        }
        _exitObservationTimer?.cancel();
        _exitObservationTimer = Timer(
          _policy.config.exitObservation,
          () => unawaited(_emitRecoveredExitIfNeeded()),
        );
      }),
    );
  }

  static Future<void> _emitRecoveredExitIfNeeded() async {
    final observation = await _policy.consumeExitObservationIfQualified();
    if (observation == null) {
      return;
    }
    final attempt = _lastClosedAttempt;
    await ProductAnalytics.instance.track(
      ProductAnalyticsEventName.userExitAfterAd,
      parameters: {
        ...?attempt?.parameters,
        ProductAnalyticsParameter.placement: observation.placement.wireName,
        ProductAnalyticsParameter.adPlacement: observation.placement.wireName,
        ProductAnalyticsParameter.isPremium: false,
        ProductAnalyticsParameter.monetizationId: observation.observationId,
        ProductAnalyticsParameter.sourceSurface: 'recommendations',
        ProductAnalyticsParameter.outcomeCategory:
            'backgrounded_without_15s_return',
      },
      transitionId: '${observation.observationId}:exit',
    );
    _lastClosedAttempt = null;
  }

  static Future<void> _handleAdShown() async {
    final placement = _activePlacement;
    final attempt = _analyticsAttempt;
    if (placement == null || attempt == null || attempt.terminal) {
      return;
    }
    await _policy.markShown(placement);
    await _trackAttempt(
      ProductAnalyticsEventName.interstitialShown,
      attempt,
      suffix: 'shown',
      additional: {
        ProductAnalyticsParameter.interstitialCountSession:
            _policy.shownCountSession,
        ProductAnalyticsParameter.interstitialCountDay: _policy.shownCountDay,
      },
    );
  }

  static Future<void> _handleAdDismissed(AdPlacement placement) async {
    await _lastShowWrite;
    final attempt = _analyticsAttempt;
    if (attempt == null) {
      return;
    }
    _lastCloseWrite = _policy.markClosed(placement, observationId: attempt.id);
    await _lastCloseWrite;
    await _trackAttempt(
      ProductAnalyticsEventName.interstitialClosed,
      attempt,
      suffix: 'closed',
      additional: {
        ProductAnalyticsParameter.interstitialCountSession:
            _policy.shownCountSession,
        ProductAnalyticsParameter.interstitialCountDay: _policy.shownCountDay,
        ProductAnalyticsParameter.outcomeCategory: 'dismissed_to_app',
      },
    );
    attempt.terminal = true;
    _lastClosedAttempt = attempt;
    _analyticsAttempt = null;
  }

  static Future<void> _handleLoadFailure() async {
    await _trackFailure('load', 'provider_callback');
    await _finishSkippedNotLoaded('load_failed');
  }

  static Future<void> _finishSkippedNotLoaded(String outcome) async {
    final attempt = _analyticsAttempt;
    if (attempt == null || attempt.terminal || _showInFlight) {
      return;
    }
    await _trackAttempt(
      ProductAnalyticsEventName.interstitialSkippedNotLoaded,
      attempt,
      suffix: 'skipped-not-loaded',
      additional: {ProductAnalyticsParameter.outcomeCategory: outcome},
    );
    _finishAttempt();
  }

  static Future<void> _trackFailure(String stage, String outcome) async {
    final attempt = _analyticsAttempt;
    if (attempt == null || attempt.terminal) {
      return;
    }
    await _trackAttempt(
      ProductAnalyticsEventName.interstitialFailed,
      attempt,
      suffix: 'failed-$stage',
      additional: {
        ProductAnalyticsParameter.failureStage: stage,
        ProductAnalyticsParameter.outcomeCategory: outcome,
      },
    );
  }

  static Future<void> _trackAttempt(
    ProductAnalyticsEventName event,
    _InterstitialAnalyticsAttempt attempt, {
    required String suffix,
    Map<ProductAnalyticsParameter, Object?> additional = const {},
  }) async {
    await ProductAnalytics.instance.track(
      event,
      parameters: {...attempt.parameters, ...additional},
      transitionId: '${attempt.id}:$suffix',
    );
  }

  static void _onPaidEvent(
    Ad ad,
    double valueMicros,
    PrecisionType precision,
    String currencyCode,
  ) {
    final attempt = _analyticsAttempt ?? _lastClosedAttempt;
    if (attempt == null || valueMicros < 0 || currencyCode.isEmpty) {
      return;
    }
    unawaited(
      _trackAttempt(
        ProductAnalyticsEventName.adRevenuePaid,
        attempt,
        suffix: 'revenue',
        additional: {
          ProductAnalyticsParameter.revenueMicros: valueMicros.round(),
          ProductAnalyticsParameter.currencyCode: currencyCode.toUpperCase(),
          ProductAnalyticsParameter.adFormat: 'interstitial',
          ProductAnalyticsParameter.providerCategory: 'google_mobile_ads',
          ProductAnalyticsParameter.outcomeCategory: precision.name
              .toLowerCase(),
        },
      ),
    );
  }

  static void _finishAttempt() {
    final attempt = _analyticsAttempt;
    if (attempt != null) {
      attempt.terminal = true;
    }
    _analyticsAttempt = null;
  }

  static Future<void> _disposeInterstitialInventory() async {
    _loadInFlight = false;
    _finishAttempt();
    final inventory = _interstitial;
    _interstitial = null;
    if (inventory != null) {
      await inventory.dispose();
    }
  }

  /// Allows a future connectivity adapter to invalidate stale inventory and
  /// retry demanded formats after recovery without exposing provider objects.
  static Future<void> setNetworkAvailable(bool value) => Future.wait([
    managedFormatInventory.setNetworkAvailable(value),
    ..._nativePlacements.map(
      (placement) => placement.setNetworkAvailable(value),
    ),
  ]);

  static NativeAdPlacementInventory createNativePlacementInventory({
    required String placement,
    required String sourceSurface,
    required int contentPosition,
  }) {
    late final _ManagedNativePlacementInventory inventory;
    inventory = _ManagedNativePlacementInventory(
      provider: _managedFormatProvider,
      placement: placement,
      sourceSurface: sourceSurface,
      contentPosition: contentPosition,
      onDispose: () => _nativePlacements.remove(inventory),
    );
    _nativePlacements.add(inventory);
    unawaited(
      inventory.configure(
        infrastructureEnabled:
            _nativeInfrastructureByPlacement[placement] ?? false,
        suppressed: _premium || !_privacy.snapshot.canRequestAds,
      ),
    );
    return inventory;
  }

  static Future<void> dispose() async {
    _exitObservationTimer?.cancel();
    _exitObservationTimer = null;
    await _disposeInterstitialInventory();
    final managedInventory = _managedFormatInventory;
    _managedFormatInventory = null;
    if (managedInventory != null) {
      await managedInventory.dispose();
    }
    final nativePlacements = _nativePlacements.toList(growable: false);
    _nativePlacements.clear();
    await Future.wait(
      nativePlacements.map((placement) => placement.disposeAsync()),
    );
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver);
      _observerRegistered = false;
    }
  }

  static void _registerLifecycleObserver() {
    if (_observerRegistered) {
      return;
    }
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _observerRegistered = true;
  }

  static void _restoreFocus() {
    final focus = _focusBeforeInterstitial;
    _focusBeforeInterstitial = null;
    if (focus == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focus.canRequestFocus) {
        focus.requestFocus();
      }
    });
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5540129750283532/2008742121';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-5540129750283532/4127478852';
    }
    throw UnsupportedError('Unsupported ad platform');
  }

  static void _diagnose(String message) {
    if (kDebugMode) {
      debugPrint('AdManager: $message');
    }
  }
}

class _ManagedNativePlacementInventory extends ChangeNotifier
    implements NativeAdPlacementInventory {
  _ManagedNativePlacementInventory({
    required AdInventoryProvider provider,
    required this.placement,
    required this.sourceSurface,
    required this.contentPosition,
    required VoidCallback onDispose,
  }) : _onDispose = onDispose,
       monetizationId = createProductAnalyticsId('native') {
    _coordinator = AdInventoryCoordinator(
      provider: provider,
      onChanged: _inventoryChanged,
      onEvent: _handleInventoryEvent,
    );
  }

  final String placement;
  final String sourceSurface;
  final int contentPosition;
  final String monetizationId;
  final VoidCallback _onDispose;
  late final AdInventoryCoordinator _coordinator;
  Future<void> _configuration = Future.value();
  bool _eligibleTracked = false;
  bool _disposed = false;
  Future<void>? _disposeFuture;

  Map<ProductAnalyticsParameter, Object?> get _analyticsContext => {
    ProductAnalyticsParameter.placement: placement,
    ProductAnalyticsParameter.adPlacement: placement,
    ProductAnalyticsParameter.isPremium: false,
    ProductAnalyticsParameter.sourceSurface: sourceSurface,
    ProductAnalyticsParameter.adFormat: 'native',
    ProductAnalyticsParameter.monetizationId: monetizationId,
    ProductAnalyticsParameter.outcomeCategory: 'after_content_$contentPosition',
  };

  Future<void> configure({
    required bool infrastructureEnabled,
    required bool suppressed,
  }) {
    return _configuration = _configuration.then((_) async {
      if (_disposed) {
        return;
      }
      await _coordinator.configure(
        infrastructureEnabled: infrastructureEnabled,
      );
      await _coordinator.setSuppressed(suppressed);
    });
  }

  Future<void> setSuppressed(bool value) async {
    await _configuration;
    if (!_disposed) {
      await _coordinator.setSuppressed(value);
    }
  }

  Future<void> setNetworkAvailable(bool value) async {
    await _configuration;
    if (!_disposed) {
      await _coordinator.setNetworkAvailable(value);
    }
  }

  @override
  NativeAdResource? get resource =>
      _disposed ? null : _coordinator.nativeResource;

  @override
  Future<AdPrepareResult> prepare() async {
    await _configuration;
    if (_disposed) {
      return AdPrepareResult.disposed;
    }
    if (!await AdManager._ensureConsentForAdRequest()) {
      return AdPrepareResult.unavailable;
    }
    await setSuppressed(AdManager._premium);
    if (!_eligibleTracked) {
      _eligibleTracked = true;
      unawaited(
        ProductAnalytics.instance.track(
          ProductAnalyticsEventName.nativeAdEligible,
          parameters: _analyticsContext,
          transitionId: '$monetizationId:eligible',
        ),
      );
    }
    return _coordinator.preloadNative();
  }

  void _handleInventoryEvent(AdInventoryEvent event) {
    if (event.type == AdInventoryEventType.impression ||
        event.type == AdInventoryEventType.clicked) {
      unawaited(
        AdManager.recordMonetizationInteraction(
          MonetizationInteraction.nativeAd,
        ),
      );
    }
    final (analyticsEvent, suffix) = switch (event.type) {
      AdInventoryEventType.impression => (
        ProductAnalyticsEventName.nativeAdImpression,
        'impression',
      ),
      AdInventoryEventType.clicked => (
        ProductAnalyticsEventName.nativeAdClicked,
        'clicked',
      ),
      AdInventoryEventType.failed => (
        ProductAnalyticsEventName.nativeAdFailed,
        'failed',
      ),
      _ => (null, null),
    };
    if (analyticsEvent == null || suffix == null) {
      return;
    }
    unawaited(
      ProductAnalytics.instance.track(
        analyticsEvent,
        parameters: {
          ..._analyticsContext,
          if (event.type == AdInventoryEventType.failed)
            ProductAnalyticsParameter.failureStage: 'provider',
        },
        transitionId: '${event.attemptId}:$suffix',
      ),
    );
  }

  void _inventoryChanged() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _onDispose();
    _disposeFuture = _coordinator.dispose();
    super.dispose();
  }

  Future<void> disposeAsync() {
    dispose();
    return _disposeFuture ?? Future.value();
  }
}

class _InterstitialAnalyticsAttempt {
  _InterstitialAnalyticsAttempt({
    required this.id,
    required this.placement,
    required this.parameters,
  });

  final String id;
  final AdPlacement placement;
  final Map<ProductAnalyticsParameter, Object?> parameters;
  bool terminal = false;
}

class _AdLifecycleObserver with WidgetsBindingObserver {
  const _AdLifecycleObserver(this.onStateChanged);

  final ValueChanged<AppLifecycleState> onStateChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
