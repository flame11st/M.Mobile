import 'dart:async';

import 'package:flutter/widgets.dart';

enum ManagedAdFormat { native, rewarded }

enum ManagedAdState {
  idle,
  loading,
  ready,
  showing,
  completed,
  dismissedWithoutReward,
  failed,
  disposed,
}

enum AdPrepareResult {
  started,
  alreadyLoading,
  ready,
  unavailable,
  disposed,
}

enum RewardedShowResult { started, unavailable }

enum AdInventoryEventType {
  loaded,
  impression,
  clicked,
  shown,
  closed,
  failed,
  authoritativeReward,
}

@immutable
class ManagedAdSnapshot {
  const ManagedAdSnapshot({
    required this.state,
    this.loadAttempts = 0,
    this.failureCode,
  });

  const ManagedAdSnapshot.idle()
      : state = ManagedAdState.idle,
        loadAttempts = 0,
        failureCode = null;

  final ManagedAdState state;
  final int loadAttempts;
  final String? failureCode;

  bool get isReady => state == ManagedAdState.ready;
}

@immutable
class AuthoritativeAdReward {
  const AuthoritativeAdReward({
    required this.idempotencyKey,
    required this.amount,
    required this.type,
  });

  final String idempotencyKey;
  final num amount;
  final String type;
}

@immutable
class AdInventoryEvent {
  const AdInventoryEvent({
    required this.format,
    required this.type,
    required this.attemptId,
    this.failureCode,
    this.reward,
  });

  final ManagedAdFormat format;
  final AdInventoryEventType type;
  final String attemptId;
  final String? failureCode;
  final AuthoritativeAdReward? reward;
}

class AdInventoryException implements Exception {
  const AdInventoryException(this.code);

  final String code;

  @override
  String toString() => 'AdInventoryException($code)';
}

class NativeAdProviderCallbacks {
  const NativeAdProviderCallbacks({
    required this.onImpression,
    required this.onClicked,
    required this.onClosed,
    required this.onFailure,
  });

  final VoidCallback onImpression;
  final VoidCallback onClicked;
  final VoidCallback onClosed;
  final ValueChanged<String> onFailure;
}

class RewardedAdProviderCallbacks {
  const RewardedAdProviderCallbacks({
    required this.onShown,
    required this.onImpression,
    required this.onClicked,
    required this.onReward,
    required this.onDismissed,
    required this.onFailure,
  });

  final VoidCallback onShown;
  final VoidCallback onImpression;
  final VoidCallback onClicked;
  final void Function(num amount, String type) onReward;
  final VoidCallback onDismissed;
  final ValueChanged<String> onFailure;
}

abstract interface class NativeAdResource {
  Widget buildView();

  Future<void> dispose();
}

abstract interface class RewardedAdResource {
  Future<void> show(RewardedAdProviderCallbacks callbacks);

  Future<void> dispose();
}

abstract interface class AdInventoryProvider {
  Future<NativeAdResource> loadNative(NativeAdProviderCallbacks callbacks);

  Future<RewardedAdResource> loadRewarded();

  Future<void> dispose();
}

/// Provider-neutral inventory owned by one approved native placement.
///
/// A placement handle owns exactly one provider resource. Separate handles are
/// required when two native surfaces can be visible at the same time because a
/// provider view cannot be mounted in more than one widget subtree.
abstract interface class NativeAdPlacementInventory implements Listenable {
  Future<AdPrepareResult> prepare();

  NativeAdResource? get resource;

  void dispose();
}

class UnavailableAdInventoryProvider implements AdInventoryProvider {
  const UnavailableAdInventoryProvider([this.reason = 'provider_disabled']);

  final String reason;

  @override
  Future<NativeAdResource> loadNative(
    NativeAdProviderCallbacks callbacks,
  ) =>
      Future.error(AdInventoryException(reason));

  @override
  Future<RewardedAdResource> loadRewarded() =>
      Future.error(AdInventoryException(reason));

  @override
  Future<void> dispose() async {}
}

@immutable
class AdInventoryRetryPolicy {
  const AdInventoryRetryPolicy({
    this.maximumLoadAttempts = 3,
    this.baseDelay = const Duration(seconds: 2),
    this.maximumDelay = const Duration(seconds: 30),
  });

  final int maximumLoadAttempts;
  final Duration baseDelay;
  final Duration maximumDelay;

  Duration delayAfter(int failedAttempt) {
    final exponent = (failedAttempt - 1).clamp(0, 20);
    final multiplier = 1 << exponent;
    final milliseconds = baseDelay.inMilliseconds * multiplier;
    return Duration(
      milliseconds: milliseconds.clamp(0, maximumDelay.inMilliseconds),
    );
  }
}

typedef AdInventoryDelay = Future<void> Function(Duration duration);
typedef AdInventoryIdFactory = String Function(String prefix);
typedef AdInventoryEventSink = void Function(AdInventoryEvent event);
typedef AuthoritativeRewardSink = void Function(AuthoritativeAdReward reward);

/// Owns native and rewarded inventory without exposing provider SDK objects.
///
/// Product surfaces can ask for a preload, inspect readiness, and continue when
/// inventory is unavailable. Enabling a product placement remains a separate
/// policy decision; this coordinator starts disabled and never enables itself.
class AdInventoryCoordinator {
  AdInventoryCoordinator({
    required AdInventoryProvider provider,
    AdInventoryRetryPolicy retryPolicy = const AdInventoryRetryPolicy(),
    AdInventoryDelay delay = _defaultDelay,
    AdInventoryIdFactory? idFactory,
    AdInventoryEventSink? onEvent,
    VoidCallback? onChanged,
  })  : _provider = provider,
        _retryPolicy = retryPolicy,
        _delay = delay,
        _idFactory = idFactory,
        _onEvent = onEvent,
        _onChanged = onChanged;

  final AdInventoryProvider _provider;
  final AdInventoryRetryPolicy _retryPolicy;
  final AdInventoryDelay _delay;
  final AdInventoryIdFactory? _idFactory;
  final AdInventoryEventSink? _onEvent;
  final VoidCallback? _onChanged;

  ManagedAdSnapshot _native = const ManagedAdSnapshot.idle();
  ManagedAdSnapshot _rewarded = const ManagedAdSnapshot.idle();
  NativeAdResource? _nativeResource;
  RewardedAdResource? _rewardedResource;
  RewardedAdResource? _activeRewardedResource;
  bool _infrastructureEnabled = false;
  bool _suppressed = true;
  bool _foreground = true;
  bool _networkAvailable = true;
  bool _disposed = false;
  bool _nativeDesired = false;
  bool _rewardedDesired = false;
  int _nativeGeneration = 0;
  int _rewardedGeneration = 0;
  int _nativeAttempts = 0;
  int _rewardedAttempts = 0;
  int _sequence = 0;
  final Set<String> _emittedTransitions = {};
  final List<VoidCallback> _listeners = <VoidCallback>[];

  ManagedAdSnapshot get native => _native;
  ManagedAdSnapshot get rewarded => _rewarded;
  NativeAdResource? get nativeResource =>
      _native.isReady ? _nativeResource : null;
  bool get isInfrastructureEnabled => _infrastructureEnabled;
  bool get isSuppressed => _suppressed;

  void addListener(VoidCallback listener) {
    if (!_disposed && !_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  Future<void> configure({required bool infrastructureEnabled}) async {
    if (_disposed || _infrastructureEnabled == infrastructureEnabled) {
      return;
    }
    _infrastructureEnabled = infrastructureEnabled;
    if (!infrastructureEnabled) {
      _nativeDesired = false;
      _rewardedDesired = false;
      await _invalidateInventory();
      return;
    }
    _resumeDesiredInventory();
  }

  Future<void> setSuppressed(bool value) async {
    if (_disposed || _suppressed == value) {
      return;
    }
    _suppressed = value;
    if (value) {
      // Premium, an unresolved entitlement, and account transitions all fail
      // closed. A later account must explicitly request fresh inventory.
      _nativeDesired = false;
      _rewardedDesired = false;
      await _invalidateInventory();
      return;
    }
    _resumeDesiredInventory();
  }

  void setForeground(bool value) {
    if (_disposed || _foreground == value) {
      return;
    }
    _foreground = value;
    if (value) {
      _resumeDesiredInventory();
    }
  }

  Future<void> setNetworkAvailable(bool value) async {
    if (_disposed || _networkAvailable == value) {
      return;
    }
    _networkAvailable = value;
    if (!value) {
      // Loaded inventory may be stale after a connectivity transition. Keep
      // demand, dispose the provider objects, and load afresh on recovery.
      await _invalidateInventory(clearDemand: false);
      return;
    }
    _resumeDesiredInventory();
  }

  AdPrepareResult preloadNative() {
    if (_disposed) {
      return AdPrepareResult.disposed;
    }
    if (!_infrastructureEnabled || _suppressed) {
      return AdPrepareResult.unavailable;
    }
    _nativeDesired = true;
    if (_native.isReady) {
      return AdPrepareResult.ready;
    }
    if (_native.state == ManagedAdState.loading) {
      return AdPrepareResult.alreadyLoading;
    }
    if (!_canPrepare) {
      return AdPrepareResult.unavailable;
    }
    _nativeAttempts = 0;
    _beginNativeLoad();
    return AdPrepareResult.started;
  }

  AdPrepareResult preloadRewarded() {
    if (_disposed) {
      return AdPrepareResult.disposed;
    }
    if (!_infrastructureEnabled || _suppressed) {
      return AdPrepareResult.unavailable;
    }
    _rewardedDesired = true;
    if (_rewarded.isReady) {
      return AdPrepareResult.ready;
    }
    if (_rewarded.state == ManagedAdState.loading) {
      return AdPrepareResult.alreadyLoading;
    }
    if (!_canPrepare) {
      return AdPrepareResult.unavailable;
    }
    _rewardedAttempts = 0;
    _beginRewardedLoad();
    return AdPrepareResult.started;
  }

  Future<RewardedShowResult> showRewarded({
    required AuthoritativeRewardSink onReward,
  }) async {
    if (_disposed || !_canPrepare || !_rewarded.isReady) {
      return RewardedShowResult.unavailable;
    }
    final resource = _rewardedResource;
    if (resource == null) {
      return RewardedShowResult.unavailable;
    }

    _rewardedResource = null;
    _activeRewardedResource = resource;
    _rewardedDesired = false;
    final generation = _rewardedGeneration;
    final attemptId = _newId('rewarded-show');
    var terminal = false;
    var rewardDelivered = false;
    _setRewarded(ManagedAdState.showing);

    Future<void> finish({required bool failed, String? failureCode}) async {
      if (terminal || generation != _rewardedGeneration || _disposed) {
        return;
      }
      terminal = true;
      _activeRewardedResource = null;
      await resource.dispose();
      if (failed) {
        _setRewarded(
          ManagedAdState.failed,
          failureCode: failureCode ?? 'playback_failed',
        );
        _emitOnce(
          AdInventoryEvent(
            format: ManagedAdFormat.rewarded,
            type: AdInventoryEventType.failed,
            attemptId: attemptId,
            failureCode: failureCode ?? 'playback_failed',
          ),
        );
      } else {
        _setRewarded(
          rewardDelivered
              ? ManagedAdState.completed
              : ManagedAdState.dismissedWithoutReward,
        );
        _emitOnce(
          AdInventoryEvent(
            format: ManagedAdFormat.rewarded,
            type: AdInventoryEventType.closed,
            attemptId: attemptId,
          ),
        );
      }
    }

    try {
      await resource.show(
        RewardedAdProviderCallbacks(
          onShown: () {
            if (terminal || generation != _rewardedGeneration || _disposed) {
              return;
            }
            _emitOnce(
              AdInventoryEvent(
                format: ManagedAdFormat.rewarded,
                type: AdInventoryEventType.shown,
                attemptId: attemptId,
              ),
            );
          },
          onImpression: () => _emitRewardedProviderEvent(
            generation,
            terminal,
            attemptId,
            AdInventoryEventType.impression,
          ),
          onClicked: () => _emitRewardedProviderEvent(
            generation,
            terminal,
            attemptId,
            AdInventoryEventType.clicked,
          ),
          onReward: (amount, type) {
            if (terminal ||
                rewardDelivered ||
                generation != _rewardedGeneration ||
                _disposed) {
              return;
            }
            rewardDelivered = true;
            final reward = AuthoritativeAdReward(
              idempotencyKey: '$attemptId:reward',
              amount: amount,
              type: type,
            );
            _emitOnce(
              AdInventoryEvent(
                format: ManagedAdFormat.rewarded,
                type: AdInventoryEventType.authoritativeReward,
                attemptId: attemptId,
                reward: reward,
              ),
            );
            onReward(reward);
          },
          onDismissed: () => unawaited(finish(failed: false)),
          onFailure: (code) =>
              unawaited(finish(failed: true, failureCode: code)),
        ),
      );
      return RewardedShowResult.started;
    } catch (error) {
      await finish(failed: true, failureCode: _failureCode(error));
      return RewardedShowResult.unavailable;
    }
  }

  bool get _canPrepare =>
      _infrastructureEnabled &&
      !_suppressed &&
      _foreground &&
      _networkAvailable;

  void _beginNativeLoad() {
    if (!_nativeDesired || !_canPrepare || _disposed) {
      return;
    }
    final generation = _nativeGeneration;
    final attemptId = _newId('native-load');
    _nativeAttempts++;
    _setNative(ManagedAdState.loading);

    unawaited(() async {
      try {
        final resource = await _provider.loadNative(
          NativeAdProviderCallbacks(
            onImpression: () => _emitNativeProviderEvent(
              generation,
              attemptId,
              AdInventoryEventType.impression,
            ),
            onClicked: () => _emitNativeProviderEvent(
              generation,
              attemptId,
              AdInventoryEventType.clicked,
            ),
            onClosed: () => _emitNativeProviderEvent(
              generation,
              attemptId,
              AdInventoryEventType.closed,
            ),
            onFailure: (code) => unawaited(
              _handleNativeRuntimeFailure(generation, attemptId, code),
            ),
          ),
        );
        if (generation != _nativeGeneration || !_canPrepare || _disposed) {
          await resource.dispose();
          return;
        }
        final oldResource = _nativeResource;
        _nativeResource = resource;
        if (oldResource != null) {
          await oldResource.dispose();
        }
        _setNative(ManagedAdState.ready);
        _emitOnce(
          AdInventoryEvent(
            format: ManagedAdFormat.native,
            type: AdInventoryEventType.loaded,
            attemptId: attemptId,
          ),
        );
      } catch (error) {
        if (generation != _nativeGeneration || _disposed) {
          return;
        }
        final code = _failureCode(error);
        _setNative(ManagedAdState.failed, failureCode: code);
        _emitOnce(
          AdInventoryEvent(
            format: ManagedAdFormat.native,
            type: AdInventoryEventType.failed,
            attemptId: attemptId,
            failureCode: code,
          ),
        );
        _scheduleNativeRetry(generation);
      }
    }());
  }

  void _beginRewardedLoad() {
    if (!_rewardedDesired || !_canPrepare || _disposed) {
      return;
    }
    final generation = _rewardedGeneration;
    final attemptId = _newId('rewarded-load');
    _rewardedAttempts++;
    _setRewarded(ManagedAdState.loading);

    unawaited(() async {
      try {
        final resource = await _provider.loadRewarded();
        if (generation != _rewardedGeneration || !_canPrepare || _disposed) {
          await resource.dispose();
          return;
        }
        final oldResource = _rewardedResource;
        _rewardedResource = resource;
        if (oldResource != null) {
          await oldResource.dispose();
        }
        _setRewarded(ManagedAdState.ready);
        _emitOnce(
          AdInventoryEvent(
            format: ManagedAdFormat.rewarded,
            type: AdInventoryEventType.loaded,
            attemptId: attemptId,
          ),
        );
      } catch (error) {
        if (generation != _rewardedGeneration || _disposed) {
          return;
        }
        final code = _failureCode(error);
        _setRewarded(ManagedAdState.failed, failureCode: code);
        _emitOnce(
          AdInventoryEvent(
            format: ManagedAdFormat.rewarded,
            type: AdInventoryEventType.failed,
            attemptId: attemptId,
            failureCode: code,
          ),
        );
        _scheduleRewardedRetry(generation);
      }
    }());
  }

  void _scheduleNativeRetry(int generation) {
    if (_nativeAttempts >= _retryPolicy.maximumLoadAttempts) {
      return;
    }
    unawaited(() async {
      await _delay(_retryPolicy.delayAfter(_nativeAttempts));
      if (generation == _nativeGeneration &&
          _nativeDesired &&
          _canPrepare &&
          !_disposed) {
        _beginNativeLoad();
      }
    }());
  }

  void _scheduleRewardedRetry(int generation) {
    if (_rewardedAttempts >= _retryPolicy.maximumLoadAttempts) {
      return;
    }
    unawaited(() async {
      await _delay(_retryPolicy.delayAfter(_rewardedAttempts));
      if (generation == _rewardedGeneration &&
          _rewardedDesired &&
          _canPrepare &&
          !_disposed) {
        _beginRewardedLoad();
      }
    }());
  }

  Future<void> _handleNativeRuntimeFailure(
    int generation,
    String attemptId,
    String code,
  ) async {
    if (generation != _nativeGeneration || _disposed) {
      return;
    }
    final resource = _nativeResource;
    _nativeResource = null;
    if (resource != null) {
      await resource.dispose();
    }
    _setNative(ManagedAdState.failed, failureCode: code);
    _emitOnce(
      AdInventoryEvent(
        format: ManagedAdFormat.native,
        type: AdInventoryEventType.failed,
        attemptId: attemptId,
        failureCode: code,
      ),
    );
    _scheduleNativeRetry(generation);
  }

  void _emitNativeProviderEvent(
    int generation,
    String attemptId,
    AdInventoryEventType type,
  ) {
    if (generation != _nativeGeneration || _disposed || !_native.isReady) {
      return;
    }
    _emitOnce(
      AdInventoryEvent(
        format: ManagedAdFormat.native,
        type: type,
        attemptId: attemptId,
      ),
    );
  }

  void _emitRewardedProviderEvent(
    int generation,
    bool terminal,
    String attemptId,
    AdInventoryEventType type,
  ) {
    if (terminal || generation != _rewardedGeneration || _disposed) {
      return;
    }
    _emitOnce(
      AdInventoryEvent(
        format: ManagedAdFormat.rewarded,
        type: type,
        attemptId: attemptId,
      ),
    );
  }

  void _emitOnce(AdInventoryEvent event) {
    final transition = '${event.attemptId}:${event.type.name}';
    if (!_emittedTransitions.add(transition)) {
      return;
    }
    _onEvent?.call(event);
  }

  Future<void> _invalidateInventory({bool clearDemand = true}) async {
    _nativeGeneration++;
    _rewardedGeneration++;
    if (clearDemand) {
      _nativeDesired = false;
      _rewardedDesired = false;
    }
    _nativeAttempts = 0;
    _rewardedAttempts = 0;
    final native = _nativeResource;
    final rewarded = _rewardedResource;
    final activeRewarded = _activeRewardedResource;
    _nativeResource = null;
    _rewardedResource = null;
    _activeRewardedResource = null;
    await Future.wait([
      if (native != null) native.dispose(),
      if (rewarded != null) rewarded.dispose(),
      if (activeRewarded != null) activeRewarded.dispose(),
    ]);
    if (!_disposed) {
      _native = const ManagedAdSnapshot.idle();
      _rewarded = const ManagedAdSnapshot.idle();
      _onChanged?.call();
    }
  }

  void _resumeDesiredInventory() {
    if (!_canPrepare || _disposed) {
      return;
    }
    if (_nativeDesired &&
        !_native.isReady &&
        _native.state != ManagedAdState.loading) {
      _nativeAttempts = 0;
      _beginNativeLoad();
    }
    if (_rewardedDesired &&
        !_rewarded.isReady &&
        _rewarded.state != ManagedAdState.loading &&
        _activeRewardedResource == null) {
      _rewardedAttempts = 0;
      _beginRewardedLoad();
    }
  }

  void _setNative(ManagedAdState state, {String? failureCode}) {
    if (_disposed) {
      return;
    }
    _native = ManagedAdSnapshot(
      state: state,
      loadAttempts: _nativeAttempts,
      failureCode: failureCode,
    );
    _notifyChanged();
  }

  void _setRewarded(ManagedAdState state, {String? failureCode}) {
    if (_disposed) {
      return;
    }
    _rewarded = ManagedAdSnapshot(
      state: state,
      loadAttempts: _rewardedAttempts,
      failureCode: failureCode,
    );
    _notifyChanged();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _nativeGeneration++;
    _rewardedGeneration++;
    final native = _nativeResource;
    final rewarded = _rewardedResource;
    final activeRewarded = _activeRewardedResource;
    _nativeResource = null;
    _rewardedResource = null;
    _activeRewardedResource = null;
    await Future.wait([
      if (native != null) native.dispose(),
      if (rewarded != null) rewarded.dispose(),
      if (activeRewarded != null) activeRewarded.dispose(),
      _provider.dispose(),
    ]);
    _native = const ManagedAdSnapshot(state: ManagedAdState.disposed);
    _rewarded = const ManagedAdSnapshot(state: ManagedAdState.disposed);
    _notifyChanged();
    _listeners.clear();
  }

  void _notifyChanged() {
    _onChanged?.call();
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);

  String _newId(String prefix) {
    final supplied = _idFactory;
    if (supplied != null) {
      return supplied(prefix);
    }
    _sequence++;
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '$prefix-$now-$_sequence';
  }

  String _nextFallbackId(String prefix) {
    _sequence++;
    return '$prefix-$_sequence';
  }

  String _failureCode(Object error) {
    if (error is AdInventoryException) {
      return error.code;
    }
    return 'provider_exception-${_nextFallbackId('failure')}';
  }
}
