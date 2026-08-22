import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AdPlacement {
  recommendationCompletion('recommendation_completion');

  const AdPlacement(this.wireName);

  final String wireName;

  static AdPlacement? fromWireName(String? value) {
    for (final placement in values) {
      if (placement.wireName == value) {
        return placement;
      }
    }
    return null;
  }
}

abstract interface class AdPolicyStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SecureAdPolicyStorage implements AdPolicyStorage {
  const SecureAdPolicyStorage([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class AdPolicyConfig {
  const AdPolicyConfig({
    this.completedActionThreshold = 4,
    this.cooldown = const Duration(hours: 24),
    this.showCandidateWindow = const Duration(seconds: 12),
    this.exitWindow = const Duration(seconds: 30),
    this.exitObservation = const Duration(seconds: 15),
  });

  const AdPolicyConfig.fromEnvironment()
      : completedActionThreshold = const int.fromEnvironment(
          'MOVIEDIARY_AD_COMPLETED_ACTION_THRESHOLD',
          defaultValue: 4,
        ),
        cooldown = const Duration(
          hours: int.fromEnvironment(
            'MOVIEDIARY_AD_COOLDOWN_HOURS',
            defaultValue: 24,
          ),
        ),
        showCandidateWindow = const Duration(
          seconds: int.fromEnvironment(
            'MOVIEDIARY_AD_SHOW_WINDOW_SECONDS',
            defaultValue: 12,
          ),
        ),
        exitWindow = const Duration(seconds: 30),
        exitObservation = const Duration(seconds: 15);

  final int completedActionThreshold;
  final Duration cooldown;
  final Duration showCandidateWindow;
  final Duration exitWindow;
  final Duration exitObservation;
}

class AdPolicyDecision {
  const AdPolicyDecision({
    required this.shouldAttempt,
    required this.completedActions,
    required this.actionsUntilEligible,
  });

  final bool shouldAttempt;
  final int completedActions;
  final int actionsUntilEligible;
}

typedef AdPolicyClock = DateTime Function();

class AdPolicyController {
  AdPolicyController({
    AdPolicyStorage? storage,
    AdPolicyClock? clock,
    this.config = const AdPolicyConfig.fromEnvironment(),
  })  : _storage = storage ?? const SecureAdPolicyStorage(),
        _clock = clock ?? DateTime.now;

  static const storageKey = 'adPolicyV1';

  final AdPolicyStorage _storage;
  final AdPolicyClock _clock;
  final AdPolicyConfig config;

  Future<void>? _initialization;
  bool _initialized = false;
  int _completedActions = 0;
  DateTime? _lastShownAtUtc;
  AdPlacement? _pendingPlacement;
  AdPlacement? _closedPlacement;
  DateTime? _lastClosedAtUtc;
  DateTime? _backgroundedAtUtc;
  bool _premium = true;

  int get completedActions => _completedActions;
  AdPlacement? get pendingPlacement => _pendingPlacement;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final activeInitialization = _initialization;
    if (activeInitialization != null) {
      await activeInitialization;
      return;
    }

    final initialization = _restore();
    _initialization = initialization;
    try {
      await initialization;
      _initialized = true;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _restore() async {
    final encoded = await _storage.read(storageKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return;
      }
      final state = Map<String, dynamic>.from(decoded);
      _completedActions = _nonNegativeInt(state['completedActions']);
      _lastShownAtUtc = _date(state['lastShownAtUtc']);
      _pendingPlacement =
          AdPlacement.fromWireName(state['pendingPlacement'] as String?);
      _closedPlacement =
          AdPlacement.fromWireName(state['closedPlacement'] as String?);
      _lastClosedAtUtc = _date(state['lastClosedAtUtc']);
      _backgroundedAtUtc = _date(state['backgroundedAtUtc']);
    } catch (_) {
      _completedActions = 0;
      _lastShownAtUtc = null;
      _pendingPlacement = null;
      _closedPlacement = null;
      _lastClosedAtUtc = null;
      _backgroundedAtUtc = null;
    }
  }

  Future<void> setPremium(bool value) async {
    _premium = value;
    await initialize();
    if (value) {
      final hadAdState = _completedActions != 0 ||
          _pendingPlacement != null ||
          _closedPlacement != null ||
          _lastClosedAtUtc != null ||
          _backgroundedAtUtc != null;
      _completedActions = 0;
      _pendingPlacement = null;
      _closedPlacement = null;
      _lastClosedAtUtc = null;
      _backgroundedAtUtc = null;
      if (hadAdState) {
        await _persist();
      }
    }
  }

  Future<AdPolicyDecision> recordCompletedAction(
    AdPlacement placement, {
    required bool isPremium,
  }) async {
    await initialize();
    _premium = isPremium;
    if (_premium) {
      return const AdPolicyDecision(
        shouldAttempt: false,
        completedActions: 0,
        actionsUntilEligible: 0,
      );
    }

    _completedActions++;
    final threshold = config.completedActionThreshold < 1
        ? 1
        : config.completedActionThreshold;
    final cooldownComplete = _lastShownAtUtc == null ||
        !_clock().toUtc().isBefore(_lastShownAtUtc!.add(config.cooldown));
    final shouldAttempt = _completedActions >= threshold && cooldownComplete;
    if (shouldAttempt) {
      _pendingPlacement = placement;
    }
    await _persist();

    return AdPolicyDecision(
      shouldAttempt: shouldAttempt,
      completedActions: _completedActions,
      actionsUntilEligible: shouldAttempt
          ? 0
          : (threshold - _completedActions).clamp(0, threshold).toInt(),
    );
  }

  Future<bool> shouldShowNow({
    required bool isPremium,
    required bool isForeground,
    required bool consentGranted,
    required bool inventoryReady,
  }) async {
    await initialize();
    return !_premium &&
        !isPremium &&
        isForeground &&
        consentGranted &&
        inventoryReady &&
        _pendingPlacement != null;
  }

  Future<void> markShown(AdPlacement placement) async {
    await initialize();
    if (_pendingPlacement != placement) {
      return;
    }
    _completedActions = 0;
    _lastShownAtUtc = _clock().toUtc();
    _pendingPlacement = null;
    await _persist();
  }

  Future<void> markClosed(AdPlacement placement) async {
    await initialize();
    _lastClosedAtUtc = _clock().toUtc();
    _closedPlacement = placement;
    _backgroundedAtUtc = null;
    await _persist();
  }

  Future<bool> markBackgrounded() async {
    await initialize();
    final closedAt = _lastClosedAtUtc;
    final now = _clock().toUtc();
    if (closedAt == null || now.difference(closedAt) > config.exitWindow) {
      return false;
    }
    _backgroundedAtUtc = now;
    await _persist();
    return true;
  }

  Future<void> markResumed() async {
    await initialize();
    if (_lastClosedAtUtc == null && _backgroundedAtUtc == null) {
      return;
    }
    _lastClosedAtUtc = null;
    _closedPlacement = null;
    _backgroundedAtUtc = null;
    await _persist();
  }

  Future<AdPlacement?> consumeExitIfQualified() async {
    await initialize();
    final closedAt = _lastClosedAtUtc;
    final backgroundedAt = _backgroundedAtUtc;
    if (closedAt == null || backgroundedAt == null) {
      return null;
    }

    final now = _clock().toUtc();
    final qualifies = !backgroundedAt.isBefore(closedAt) &&
        backgroundedAt.difference(closedAt) <= config.exitWindow &&
        now.difference(backgroundedAt) >= config.exitObservation;
    if (!qualifies) {
      return null;
    }

    final placement = _closedPlacement;
    _lastClosedAtUtc = null;
    _backgroundedAtUtc = null;
    _closedPlacement = null;
    await _persist();
    return placement;
  }

  Future<void> _persist() {
    return _storage.write(
      storageKey,
      jsonEncode({
        'completedActions': _completedActions,
        'lastShownAtUtc': _lastShownAtUtc?.toIso8601String(),
        'pendingPlacement': _pendingPlacement?.wireName,
        'closedPlacement': _closedPlacement?.wireName,
        'lastClosedAtUtc': _lastClosedAtUtc?.toIso8601String(),
        'backgroundedAtUtc': _backgroundedAtUtc?.toIso8601String(),
      }),
    );
  }

  static int _nonNegativeInt(Object? value) {
    final parsed = value is int ? value : int.tryParse('$value');
    return parsed == null || parsed < 0 ? 0 : parsed;
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }
}
