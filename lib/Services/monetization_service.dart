import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mmobile/Helpers/ad_inventory.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Helpers/ad_policy.dart';
import 'package:mmobile/Services/ad_privacy_consent.dart';
import 'package:mmobile/Services/monetization_config.dart';

enum MonetizationPlacement {
  discoverNative('discover_native'),
  generalListNative('general_list_native'),
  watchlistNative('watchlist_native'),
  viewedNative('viewed_native'),
  recommendationDeckCompletedInterstitial(
    'recommendation_deck_completed_interstitial',
  ),
  extraRecommendationRewarded('extra_recommendation_rewarded');

  const MonetizationPlacement(this.wireName);

  final String wireName;
}

enum MonetizationSurface {
  discover,
  generalList,
  recommendationDeckCompleted,
  recommendationAllowance,
  onboarding,
  authentication,
  rateMovies,
  movieDna,
  activeRecommendations,
  recommendationHistory,
  search,
  myMovies,
  watchlist,
  viewed,
  movieDetails,
  whereToWatch,
  settings,
  personalList,
  purchase,
  ratingSheet,
  markWatched,
}

enum MonetizationDenialReason {
  none,
  entitlementUnresolved,
  premium,
  absoluteAdFreeZone,
  placementNotApprovedForSurface,
  configurationDisabled,
}

@immutable
class MonetizationDecision {
  const MonetizationDecision._({
    required this.isEligible,
    required this.reason,
  });

  const MonetizationDecision.eligible()
    : this._(isEligible: true, reason: MonetizationDenialReason.none);

  const MonetizationDecision.denied(MonetizationDenialReason reason)
    : this._(isEligible: false, reason: reason);

  final bool isEligible;
  final MonetizationDenialReason reason;
}

abstract interface class MonetizationInventoryGateway {
  Future<void> initializePrivacyForLaunch();

  Future<void> markMeaningfulProductExperience();

  Future<AdPrivacyOptionsResult> showPrivacyOptions();

  Future<void> applyConfiguration(MonetizationConfig config);

  Future<void> setEntitlementState({
    required bool isPremium,
    required bool isResolved,
  });

  Future<void> prepareRecommendationCompletionInterstitial();

  Future<void> recordRecommendationDeckCompleted({
    required String completionId,
    String? recommendationSessionId,
    String? recommendationMode,
    String? mediaType,
  });

  Future<void> recordMonetizationInteraction(
    MonetizationInteraction interaction,
  );

  NativeAdPlacementInventory createNativePlacementInventory({
    required String placement,
    required String sourceSurface,
    required int contentPosition,
  });

  Future<void> dispose();
}

abstract interface class ObservableAdPrivacyInventoryGateway {
  ValueListenable<AdPrivacySnapshot> get privacySnapshotListenable;
}

class AdManagerMonetizationInventoryGateway
    implements
        MonetizationInventoryGateway,
        ObservableAdPrivacyInventoryGateway {
  const AdManagerMonetizationInventoryGateway();

  @override
  ValueListenable<AdPrivacySnapshot> get privacySnapshotListenable =>
      AdManager.privacySnapshotListenable;

  @override
  Future<void> initializePrivacyForLaunch() =>
      AdManager.initializePrivacyForLaunch();

  @override
  Future<void> markMeaningfulProductExperience() =>
      AdManager.markMeaningfulProductExperience();

  @override
  Future<AdPrivacyOptionsResult> showPrivacyOptions() =>
      AdManager.showPrivacyOptions();

  @override
  Future<void> applyConfiguration(MonetizationConfig config) =>
      AdManager.applyConfiguration(config);

  @override
  Future<void> setEntitlementState({
    required bool isPremium,
    required bool isResolved,
  }) {
    // An unresolved entitlement fails closed so cached inventory cannot appear
    // while an account or restored purchase is being refreshed.
    return AdManager.setPremiumStatus(isPremium || !isResolved);
  }

  @override
  Future<void> prepareRecommendationCompletionInterstitial() =>
      AdManager.prepareRecommendationCompletionInterstitial();

  @override
  Future<void> recordRecommendationDeckCompleted({
    required String completionId,
    String? recommendationSessionId,
    String? recommendationMode,
    String? mediaType,
  }) {
    return AdManager.recordDeckCompleted(
      AdPlacement.recommendationCompletion,
      completionId: completionId,
      isPremium: false,
      recommendationSessionId: recommendationSessionId,
      recommendationMode: recommendationMode,
      mediaType: mediaType,
    );
  }

  @override
  Future<void> recordMonetizationInteraction(
    MonetizationInteraction interaction,
  ) {
    return AdManager.recordMonetizationInteraction(interaction);
  }

  @override
  NativeAdPlacementInventory createNativePlacementInventory({
    required String placement,
    required String sourceSurface,
    required int contentPosition,
  }) {
    return AdManager.createNativePlacementInventory(
      placement: placement,
      sourceSurface: sourceSurface,
      contentPosition: contentPosition,
    );
  }

  @override
  Future<void> dispose() => AdManager.dispose();
}

class MonetizationService with ChangeNotifier {
  MonetizationService({
    MonetizationInventoryGateway? inventoryGateway,
    MonetizationConfigService? configService,
  }) : _inventoryGateway =
           inventoryGateway ?? const AdManagerMonetizationInventoryGateway(),
       _configService = configService ?? MonetizationConfigService() {
    _configService.addListener(_configurationChanged);
    if (_inventoryGateway is ObservableAdPrivacyInventoryGateway) {
      final observableGateway =
          _inventoryGateway as ObservableAdPrivacyInventoryGateway;
      _privacyListenable = observableGateway.privacySnapshotListenable;
      _privacySnapshot = _privacyListenable!.value;
      _privacyListenable!.addListener(_privacyChanged);
    }
  }

  static const Map<MonetizationPlacement, Set<MonetizationSurface>>
  approvedPlacementSurfaces = {
    MonetizationPlacement.discoverNative: {MonetizationSurface.discover},
    MonetizationPlacement.generalListNative: {MonetizationSurface.generalList},
    MonetizationPlacement.watchlistNative: {MonetizationSurface.watchlist},
    MonetizationPlacement.viewedNative: {MonetizationSurface.viewed},
    MonetizationPlacement.recommendationDeckCompletedInterstitial: {
      MonetizationSurface.recommendationDeckCompleted,
    },
    MonetizationPlacement.extraRecommendationRewarded: {
      MonetizationSurface.recommendationAllowance,
    },
  };

  static const Set<MonetizationSurface> absoluteAdFreeZones = {
    MonetizationSurface.onboarding,
    MonetizationSurface.authentication,
    MonetizationSurface.rateMovies,
    MonetizationSurface.movieDna,
    MonetizationSurface.activeRecommendations,
    MonetizationSurface.recommendationHistory,
    MonetizationSurface.search,
    MonetizationSurface.myMovies,
    MonetizationSurface.movieDetails,
    MonetizationSurface.whereToWatch,
    MonetizationSurface.settings,
    MonetizationSurface.personalList,
    MonetizationSurface.purchase,
    MonetizationSurface.ratingSheet,
    MonetizationSurface.markWatched,
  };

  final MonetizationInventoryGateway _inventoryGateway;
  final MonetizationConfigService _configService;

  bool _isPremium = false;
  bool _isEntitlementResolved = false;
  AdPrivacySnapshot _privacySnapshot = const AdPrivacySnapshot.unresolved();
  ValueListenable<AdPrivacySnapshot>? _privacyListenable;

  bool get isPremium => _isPremium;
  bool get isEntitlementResolved => _isEntitlementResolved;
  bool get suppressesMonetization => !_isEntitlementResolved || _isPremium;
  AdPrivacySnapshot get privacySnapshot => _privacySnapshot;
  bool get privacyOptionsRequired =>
      _privacySnapshot.privacyOptionsStatusKnown &&
      _privacySnapshot.privacyOptionsRequired;
  MonetizationConfig get config => _configService.current;
  MonetizationConfigSource get configSource => _configService.source;

  Future<void> initializeConfiguration() async {
    await _inventoryGateway.initializePrivacyForLaunch();
    await _inventoryGateway.applyConfiguration(config);
    await _configService.initialize();
    await _inventoryGateway.applyConfiguration(config);
  }

  void _configurationChanged() {
    unawaited(_inventoryGateway.applyConfiguration(config));
    notifyListeners();
  }

  void _privacyChanged() {
    _privacySnapshot = _privacyListenable!.value;
    notifyListeners();
  }

  MonetizationDecision evaluate(
    MonetizationPlacement placement, {
    required MonetizationSurface surface,
  }) {
    if (absoluteAdFreeZones.contains(surface)) {
      return const MonetizationDecision.denied(
        MonetizationDenialReason.absoluteAdFreeZone,
      );
    }
    if (!(approvedPlacementSurfaces[placement]?.contains(surface) ?? false)) {
      return const MonetizationDecision.denied(
        MonetizationDenialReason.placementNotApprovedForSurface,
      );
    }
    if (!_isEntitlementResolved) {
      return const MonetizationDecision.denied(
        MonetizationDenialReason.entitlementUnresolved,
      );
    }
    if (_isPremium) {
      return const MonetizationDecision.denied(
        MonetizationDenialReason.premium,
      );
    }
    if (!_placementEnabled(placement)) {
      return const MonetizationDecision.denied(
        MonetizationDenialReason.configurationDisabled,
      );
    }
    return const MonetizationDecision.eligible();
  }

  bool _placementEnabled(MonetizationPlacement placement) =>
      switch (placement) {
        MonetizationPlacement.discoverNative =>
          config.discoverNativePlacementEnabled,
        MonetizationPlacement.generalListNative =>
          config.generalListNativePlacementEnabled,
        MonetizationPlacement.watchlistNative ||
        MonetizationPlacement.viewedNative =>
          config.myMoviesNativePlacementEnabled,
        MonetizationPlacement.recommendationDeckCompletedInterstitial =>
          config.recommendationInterstitialPlacementEnabled,
        MonetizationPlacement.extraRecommendationRewarded =>
          config.extraRecommendationRewardedPlacementEnabled,
      };

  Future<void> synchronizeEntitlement({
    required bool isPremium,
    required bool isResolved,
  }) {
    final changed =
        _isPremium != isPremium || _isEntitlementResolved != isResolved;
    _isPremium = isPremium;
    _isEntitlementResolved = isResolved;
    if (changed) {
      notifyListeners();
    }

    return _inventoryGateway.setEntitlementState(
      isPremium: isPremium,
      isResolved: isResolved,
    );
  }

  Future<void> beginEntitlementRefresh() {
    return synchronizeEntitlement(isPremium: false, isResolved: false);
  }

  Future<void> markMeaningfulProductExperience() =>
      _inventoryGateway.markMeaningfulProductExperience();

  Future<AdPrivacyOptionsResult> showPrivacyOptions() =>
      _inventoryGateway.showPrivacyOptions();

  Future<void> prepareRecommendationCompletionInterstitial() async {
    final decision = evaluate(
      MonetizationPlacement.recommendationDeckCompletedInterstitial,
      surface: MonetizationSurface.recommendationDeckCompleted,
    );
    if (!decision.isEligible) {
      return;
    }
    await _inventoryGateway.prepareRecommendationCompletionInterstitial();
  }

  Future<void> recordRecommendationDeckCompleted({
    required String completionId,
    String? recommendationSessionId,
    String? recommendationMode,
    String? mediaType,
  }) async {
    final decision = evaluate(
      MonetizationPlacement.recommendationDeckCompletedInterstitial,
      surface: MonetizationSurface.recommendationDeckCompleted,
    );
    if (!decision.isEligible) {
      return;
    }

    await _inventoryGateway.recordRecommendationDeckCompleted(
      completionId: completionId,
      recommendationSessionId: recommendationSessionId,
      recommendationMode: recommendationMode,
      mediaType: mediaType,
    );
  }

  Future<void> recordMonetizationInteraction(
    MonetizationInteraction interaction,
  ) {
    return _inventoryGateway.recordMonetizationInteraction(interaction);
  }

  NativePlacementController createNativePlacement({
    required MonetizationPlacement placement,
    required MonetizationSurface surface,
    required int contentPosition,
  }) {
    return NativePlacementController._(
      monetization: this,
      placement: placement,
      surface: surface,
      inventory: _inventoryGateway.createNativePlacementInventory(
        placement: placement.wireName,
        sourceSurface: surface.name,
        contentPosition: contentPosition,
      ),
    );
  }

  @override
  void dispose() {
    _configService.removeListener(_configurationChanged);
    _privacyListenable?.removeListener(_privacyChanged);
    unawaited(_inventoryGateway.dispose());
    super.dispose();
  }
}

/// A screen-facing, provider-neutral native placement controller.
///
/// Screens may ask this controller to prepare and render approved inventory,
/// but cannot bypass entitlement, surface, or remote-configuration policy.
class NativePlacementController extends ChangeNotifier {
  NativePlacementController._({
    required MonetizationService monetization,
    required MonetizationPlacement placement,
    required MonetizationSurface surface,
    required NativeAdPlacementInventory inventory,
  }) : _monetization = monetization,
       _placement = placement,
       _surface = surface,
       _inventory = inventory {
    _monetization.addListener(_policyChanged);
    _inventory.addListener(_inventoryChanged);
  }

  final MonetizationService _monetization;
  final MonetizationPlacement _placement;
  final MonetizationSurface _surface;
  final NativeAdPlacementInventory _inventory;
  bool _disposed = false;
  bool _preparing = false;

  bool get isEligible =>
      _monetization.evaluate(_placement, surface: _surface).isEligible;

  NativeAdResource? get resource => isEligible ? _inventory.resource : null;

  Future<AdPrepareResult> prepare() async {
    if (!isEligible) {
      return AdPrepareResult.unavailable;
    }
    if (_preparing) {
      return AdPrepareResult.alreadyLoading;
    }
    _preparing = true;
    try {
      return await _inventory.prepare();
    } finally {
      _preparing = false;
    }
  }

  void _policyChanged() {
    if (!_disposed) {
      if (isEligible && resource == null) {
        unawaited(prepare());
      }
      notifyListeners();
    }
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
    _monetization.removeListener(_policyChanged);
    _inventory.removeListener(_inventoryChanged);
    _inventory.dispose();
    super.dispose();
  }
}
