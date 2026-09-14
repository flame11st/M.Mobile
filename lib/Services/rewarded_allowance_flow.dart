import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mmobile/Helpers/ad_inventory.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/recommendation_discovery_session.dart';
import 'package:mmobile/Services/product_analytics.dart';
import 'package:mmobile/Services/rewarded_deck_credit_service.dart';

enum RewardedAllowanceFlowState {
  available,
  loading,
  playing,
  completed,
  dismissedWithoutReward,
  failedToLoad,
  failedDuringPlayback,
  rewardLimitReached,
}

abstract interface class RewardedInventoryGateway {
  ManagedAdSnapshot get snapshot;

  void addListener(VoidCallback listener);

  void removeListener(VoidCallback listener);

  Future<AdPrepareResult> prepare();

  Future<RewardedShowResult> show({
    required AuthoritativeRewardSink onReward,
  });
}

abstract interface class RewardedCreditGateway {
  Future<RewardedDeckCreditGrant?> grant({
    required String userId,
    required AuthoritativeAdReward reward,
  });
}

class ManagedRewardedInventoryGateway implements RewardedInventoryGateway {
  ManagedRewardedInventoryGateway({AdInventoryCoordinator? coordinator})
      : _coordinator = coordinator ?? AdManager.managedFormatInventory;

  final AdInventoryCoordinator _coordinator;

  @override
  ManagedAdSnapshot get snapshot => _coordinator.rewarded;

  @override
  void addListener(VoidCallback listener) => _coordinator.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _coordinator.removeListener(listener);

  @override
  Future<AdPrepareResult> prepare() async {
    if (!await AdManager.ensureManagedFormatConsent()) {
      return AdPrepareResult.unavailable;
    }
    return _coordinator.preloadRewarded();
  }

  @override
  Future<RewardedShowResult> show({
    required AuthoritativeRewardSink onReward,
  }) async {
    if (!await AdManager.ensureManagedFormatConsent()) {
      return RewardedShowResult.unavailable;
    }
    return _coordinator.showRewarded(onReward: onReward);
  }
}

class DurableRewardedCreditGateway implements RewardedCreditGateway {
  DurableRewardedCreditGateway({RewardedDeckCreditService? service})
      : _service = service ?? RewardedDeckCreditService();

  final RewardedDeckCreditService _service;

  @override
  Future<RewardedDeckCreditGrant?> grant({
    required String userId,
    required AuthoritativeAdReward reward,
  }) =>
      _service.grantAuthoritativeReward(userId: userId, reward: reward);
}

/// Owns the client-side value exchange without starting recommendation work.
///
/// The provider's authoritative reward is persisted first. Completion exposes
/// a durable allowance to the UI, which requires a separate user action before
/// the recommendation request is made.
class RewardedAllowanceFlowController extends ChangeNotifier {
  RewardedAllowanceFlowController({
    RewardedInventoryGateway? inventory,
    RewardedCreditGateway? credits,
    ProductAnalytics? analytics,
  })  : _inventory = inventory ?? ManagedRewardedInventoryGateway(),
        _credits = credits ?? DurableRewardedCreditGateway(),
        _analytics = analytics ?? ProductAnalytics.instance {
    _inventory.addListener(_inventoryChanged);
    _syncInventoryState();
  }

  static const _placement = 'extra_recommendation_rewarded';

  final RewardedInventoryGateway _inventory;
  final RewardedCreditGateway _credits;
  final ProductAnalytics _analytics;

  RewardedAllowanceFlowState _state = RewardedAllowanceFlowState.failedToLoad;
  RecommendationAllowance? _allowance;
  Future<RewardedDeckCreditGrant?>? _grantFuture;
  String? _attemptId;
  bool _playbackStarted = false;
  bool _rewardAccepted = false;
  bool _disposed = false;

  RewardedAllowanceFlowState get state => _state;
  RecommendationAllowance? get allowance => _allowance;
  bool get isAvailable => _state == RewardedAllowanceFlowState.available;
  bool get isBusy =>
      _state == RewardedAllowanceFlowState.loading ||
      _state == RewardedAllowanceFlowState.playing;

  Future<void> prepare() async {
    if (_disposed || _state == RewardedAllowanceFlowState.playing) {
      return;
    }
    _allowance = null;
    final result = await _inventory.prepare();
    switch (result) {
      case AdPrepareResult.ready:
        _setState(RewardedAllowanceFlowState.available);
      case AdPrepareResult.started || AdPrepareResult.alreadyLoading:
        _setState(RewardedAllowanceFlowState.loading);
      case AdPrepareResult.unavailable || AdPrepareResult.disposed:
        _setState(RewardedAllowanceFlowState.failedToLoad);
    }
  }

  Future<void> play({required String userId}) async {
    if (_disposed || userId.trim().isEmpty || !isAvailable) {
      _setState(RewardedAllowanceFlowState.failedToLoad);
      return;
    }

    _attemptId = createProductAnalyticsId('rewarded');
    _playbackStarted = true;
    _rewardAccepted = false;
    _grantFuture = null;
    _allowance = null;
    final result = await _inventory.show(
      onReward: (reward) {
        if (_rewardAccepted) {
          return;
        }
        _rewardAccepted = true;
        final grant = _credits.grant(userId: userId, reward: reward);
        _grantFuture = grant;
        unawaited(_settleGrant(grant));
      },
    );
    if (result == RewardedShowResult.unavailable) {
      _playbackStarted = false;
      unawaited(_trackFailure('show', 'inventory_unavailable'));
      _setState(RewardedAllowanceFlowState.failedToLoad);
      return;
    }

    _playbackStarted = true;
    if (_inventory.snapshot.state == ManagedAdState.showing) {
      _setState(RewardedAllowanceFlowState.playing);
    }
    unawaited(_track(ProductAnalyticsEventName.rewardedStarted, 'started'));
  }

  Future<void> _settleGrant(
    Future<RewardedDeckCreditGrant?> grantFuture,
  ) async {
    try {
      final grant = await grantFuture;
      if (_disposed || !identical(grantFuture, _grantFuture)) {
        return;
      }
      if (grant?.limitReached == true) {
        _allowance = grant?.allowance;
        unawaited(_trackFailure('credit', 'daily_reward_limit'));
        _setState(RewardedAllowanceFlowState.rewardLimitReached);
        return;
      }
      if (grant == null || (!grant.granted && !grant.alreadyProcessed)) {
        unawaited(_trackFailure('credit', 'credit_not_persisted'));
        _setState(RewardedAllowanceFlowState.failedDuringPlayback);
        return;
      }

      _allowance = grant.allowance;
      unawaited(
          _track(ProductAnalyticsEventName.rewardedCompleted, 'completed'));
      _setState(RewardedAllowanceFlowState.completed);
    } catch (_) {
      if (_disposed || !identical(grantFuture, _grantFuture)) {
        return;
      }
      unawaited(_trackFailure('credit', 'credit_persistence_exception'));
      _setState(RewardedAllowanceFlowState.failedDuringPlayback);
    }
  }

  void _inventoryChanged() {
    if (_disposed) {
      return;
    }
    _syncInventoryState();
  }

  void _syncInventoryState() {
    final managedState = _inventory.snapshot.state;
    switch (managedState) {
      case ManagedAdState.ready:
        _setState(RewardedAllowanceFlowState.available);
      case ManagedAdState.loading:
        _setState(RewardedAllowanceFlowState.loading);
      case ManagedAdState.showing:
        _setState(RewardedAllowanceFlowState.playing);
      case ManagedAdState.completed:
        final grant = _grantFuture;
        if (grant == null) {
          unawaited(_trackFailure('callback', 'reward_missing'));
          _setState(RewardedAllowanceFlowState.failedDuringPlayback);
        } else {
          unawaited(_settleGrant(grant));
        }
      case ManagedAdState.dismissedWithoutReward:
        if (_state != RewardedAllowanceFlowState.completed) {
          unawaited(
            _track(ProductAnalyticsEventName.rewardedDismissed, 'dismissed'),
          );
          _setState(RewardedAllowanceFlowState.dismissedWithoutReward);
        }
      case ManagedAdState.failed:
        unawaited(_trackFailure(
          _playbackStarted ? 'playback' : 'load',
          _inventory.snapshot.failureCode ?? 'provider_failure',
        ));
        _setState(
          _playbackStarted
              ? RewardedAllowanceFlowState.failedDuringPlayback
              : RewardedAllowanceFlowState.failedToLoad,
        );
      case ManagedAdState.idle || ManagedAdState.disposed:
        if (!_playbackStarted &&
            _state != RewardedAllowanceFlowState.completed) {
          _setState(RewardedAllowanceFlowState.failedToLoad);
        }
    }
  }

  Future<void> _track(
    ProductAnalyticsEventName event,
    String suffix,
  ) async {
    await _analytics.track(
      event,
      parameters: const {
        ProductAnalyticsParameter.placement: _placement,
        ProductAnalyticsParameter.isPremium: false,
        ProductAnalyticsParameter.sourceSurface: 'recommendation_allowance',
      },
      transitionId: '${_attemptId ?? 'rewarded-offer'}:$suffix',
    );
  }

  Future<void> _trackFailure(String stage, String outcome) async {
    await _analytics.track(
      ProductAnalyticsEventName.rewardedFailed,
      parameters: {
        ProductAnalyticsParameter.placement: _placement,
        ProductAnalyticsParameter.isPremium: false,
        ProductAnalyticsParameter.sourceSurface: 'recommendation_allowance',
        ProductAnalyticsParameter.failureStage: stage,
        ProductAnalyticsParameter.outcomeCategory: outcome,
      },
      transitionId: '${_attemptId ?? 'rewarded-offer'}:failed-$stage',
    );
  }

  void _setState(RewardedAllowanceFlowState value) {
    if (_disposed || _state == value) {
      return;
    }
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _inventory.removeListener(_inventoryChanged);
    super.dispose();
  }
}
