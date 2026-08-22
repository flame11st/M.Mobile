import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mmobile/Helpers/ad_policy.dart';
import 'package:mmobile/Services/product_analytics.dart';

class AdManager {
  static final AdPolicyController _policy = AdPolicyController();
  static const _AdLifecycleObserver _lifecycleObserver =
      _AdLifecycleObserver(_handleLifecycleState);

  static Future<InitializationStatus>? _mobileAdsInitialization;
  static InterstitialAd? _interstitial;
  static Timer? _exitObservationTimer;
  static bool _observerRegistered = false;
  static bool _premium = true;
  static bool _foreground = true;
  static bool _consentGranted = false;
  static bool _consentResolved = false;
  static bool _loadInFlight = false;
  static bool _showInFlight = false;
  static DateTime? _showCandidateDeadline;
  static AdPlacement? _activePlacement;
  static FocusNode? _focusBeforeInterstitial;
  static Future<void> _lastCloseWrite = Future.value();

  static const String _adEnvironment = String.fromEnvironment(
    'MOVIEDIARY_AD_ENVIRONMENT',
    defaultValue: 'production',
  );
  static const bool _enableDebugAds = bool.fromEnvironment(
    'MOVIEDIARY_ENABLE_DEBUG_ADS',
    defaultValue: false,
  );

  static bool get nativeAdsEnabled => !kDebugMode || _enableDebugAds;

  static Future<void> setPremiumStatus(bool value) async {
    _premium = value;
    _registerLifecycleObserver();
    await _policy.setPremium(value);

    if (value) {
      _showCandidateDeadline = null;
      _activePlacement = null;
      _showInFlight = false;
      await _disposeInventory();
      return;
    }

    await _emitRecoveredExitIfNeeded();
  }

  static Future<void> recordCompletedAction(
    AdPlacement placement, {
    required bool isPremium,
  }) async {
    _premium = isPremium;
    _registerLifecycleObserver();
    final decision = await _policy.recordCompletedAction(
      placement,
      isPremium: isPremium,
    );

    if (isPremium || !nativeAdsEnabled) {
      return;
    }

    if (decision.shouldAttempt) {
      _showCandidateDeadline =
          DateTime.now().toUtc().add(_policy.config.showCandidateWindow);
      await _prepareInventory(showWhenReady: true);
      return;
    }

    if (decision.actionsUntilEligible == 1) {
      unawaited(_prepareInventory(showWhenReady: false));
    }
  }

  static Future<void> _prepareInventory({required bool showWhenReady}) async {
    if (_premium || !nativeAdsEnabled) {
      return;
    }

    final consentGranted = await _resolveConsent();
    if (!consentGranted || _premium) {
      return;
    }

    if (_interstitial != null) {
      if (showWhenReady) {
        await _tryShow();
      }
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
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loadInFlight = false;
            if (_premium) {
              unawaited(ad.dispose());
              return;
            }
            _interstitial = ad;
            ad.fullScreenContentCallback = const FullScreenContentCallback(
              onAdShowedFullScreenContent: _onAdShown,
              onAdFailedToShowFullScreenContent: _onAdFailedToShow,
              onAdDismissedFullScreenContent: _onAdDismissed,
            );
            if (showWhenReady) {
              unawaited(_tryShow());
            }
          },
          onAdFailedToLoad: (error) {
            _loadInFlight = false;
            _diagnose('interstitial inventory unavailable: $error');
          },
        ),
      );
    } catch (error) {
      _loadInFlight = false;
      _diagnose('interstitial preparation deferred: $error');
    }
  }

  static Future<bool> _resolveConsent() async {
    if (_consentResolved) {
      return _consentGranted;
    }

    try {
      if (!Platform.isIOS) {
        _consentGranted = true;
      } else {
        var status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          status = await AppTrackingTransparency.requestTrackingAuthorization();
        }
        _consentGranted = status == TrackingStatus.authorized;
      }
    } catch (error) {
      _consentGranted = false;
      _diagnose('ad consent unavailable: $error');
    }
    _consentResolved = true;
    return _consentGranted;
  }

  static Future<void> _tryShow() async {
    final inventory = _interstitial;
    final deadline = _showCandidateDeadline;
    if (inventory == null ||
        deadline == null ||
        DateTime.now().toUtc().isAfter(deadline) ||
        _showInFlight) {
      return;
    }

    final placement = _policy.pendingPlacement;
    final shouldShow = await _policy.shouldShowNow(
      isPremium: _premium,
      isForeground: _foreground,
      consentGranted: _consentGranted,
      inventoryReady: true,
    );
    if (!shouldShow || placement == null) {
      return;
    }

    _showInFlight = true;
    _activePlacement = placement;
    _focusBeforeInterstitial = FocusManager.instance.primaryFocus;
    try {
      inventory.show();
    } catch (error) {
      _showInFlight = false;
      _activePlacement = null;
      _interstitial = null;
      unawaited(inventory.dispose());
      _diagnose('interstitial show deferred: $error');
    }
  }

  static void _onAdShown(Ad ad) {
    final placement = _activePlacement;
    _interstitial = null;
    _showCandidateDeadline = null;
    if (placement == null) {
      return;
    }

    unawaited(_policy.markShown(placement));
    unawaited(ProductAnalytics.instance.track(
      ProductAnalyticsEventName.interstitialShown,
      parameters: {
        ProductAnalyticsParameter.adPlacement: placement.wireName,
        ProductAnalyticsParameter.sourceSurface: 'recommendations',
      },
    ));
  }

  static void _onAdFailedToShow(Ad ad, AdError error) {
    _showInFlight = false;
    _activePlacement = null;
    _interstitial = null;
    _showCandidateDeadline = null;
    unawaited(ad.dispose());
    _restoreFocus();
    _diagnose('interstitial failed to show: $error');
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

    _lastCloseWrite = _policy.markClosed(placement);
    unawaited(ProductAnalytics.instance.track(
      ProductAnalyticsEventName.interstitialClosed,
      parameters: {
        ProductAnalyticsParameter.adPlacement: placement.wireName,
        ProductAnalyticsParameter.sourceSurface: 'recommendations',
        ProductAnalyticsParameter.outcomeCategory: 'dismissed_to_app',
      },
    ));
  }

  static void _handleLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _exitObservationTimer?.cancel();
      _exitObservationTimer = null;
      unawaited(_policy.markResumed());
      return;
    }

    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    unawaited(_lastCloseWrite
        .then((_) => _policy.markBackgrounded())
        .then((candidate) {
      if (!candidate) {
        return;
      }
      _exitObservationTimer?.cancel();
      _exitObservationTimer = Timer(
        _policy.config.exitObservation,
        () => unawaited(_emitRecoveredExitIfNeeded()),
      );
    }));
  }

  static Future<void> _emitRecoveredExitIfNeeded() async {
    final placement = await _policy.consumeExitIfQualified();
    if (placement == null) {
      return;
    }
    await ProductAnalytics.instance.track(
      ProductAnalyticsEventName.userExitAfterAd,
      parameters: {
        ProductAnalyticsParameter.adPlacement: placement.wireName,
        ProductAnalyticsParameter.sourceSurface: 'recommendations',
        ProductAnalyticsParameter.outcomeCategory:
            'backgrounded_without_15s_return',
      },
    );
  }

  static Future<void> _disposeInventory() async {
    _loadInFlight = false;
    final inventory = _interstitial;
    _interstitial = null;
    if (inventory != null) {
      await inventory.dispose();
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
    const useTestInventory = !kReleaseMode && _adEnvironment == 'test';
    if (Platform.isAndroid) {
      return useTestInventory
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-5540129750283532/2008742121';
    }
    if (Platform.isIOS) {
      return useTestInventory
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-5540129750283532/4127478852';
    }
    throw UnsupportedError('Unsupported ad platform');
  }

  static void _diagnose(String message) {
    if (kDebugMode) {
      debugPrint('AdManager: $message');
    }
  }
}

class _AdLifecycleObserver with WidgetsBindingObserver {
  const _AdLifecycleObserver(this.onStateChanged);

  final ValueChanged<AppLifecycleState> onStateChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
