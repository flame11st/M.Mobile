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

enum MonetizationInteraction {
  nativeAd('native_ad'),
  rewardedAd('rewarded_ad'),
  premiumPrompt('premium_prompt'),
  interstitial('interstitial');

  const MonetizationInteraction(this.wireName);

  final String wireName;
}

enum AdPolicyDenialReason {
  none('eligible'),
  premium('premium'),
  disabled('configuration_disabled'),
  firstSession('first_session'),
  firstDeckOfDay('first_deck_of_day'),
  cooldown('cooldown'),
  sessionCap('session_cap'),
  dayCap('day_cap'),
  recentMonetization('recent_monetization'),
  notForeground('not_foreground'),
  consentUnavailable('consent_unavailable'),
  inventoryNotReady('inventory_not_ready'),
  duplicateCompletion('duplicate_completion');

  const AdPolicyDenialReason(this.wireName);

  final String wireName;

  bool get isFrequencyProtection => switch (this) {
        firstSession ||
        firstDeckOfDay ||
        cooldown ||
        sessionCap ||
        dayCap ||
        recentMonetization =>
          true,
        _ => false,
      };
}

abstract interface class AdPolicyStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
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

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class AdPolicyConfig {
  const AdPolicyConfig({
    this.enabled = true,
    this.cooldown = const Duration(minutes: 10),
    this.maxPerSession = 2,
    this.maxPerDay = 3,
    this.firstSessionEnabled = false,
    this.firstDeckOfDayEnabled = false,
    this.recentInteractionWindow = const Duration(minutes: 10),
    this.exitWindow = const Duration(seconds: 30),
    this.exitObservation = const Duration(seconds: 15),
  });

  final bool enabled;
  final Duration cooldown;
  final int maxPerSession;
  final int maxPerDay;
  final bool firstSessionEnabled;
  final bool firstDeckOfDayEnabled;
  final Duration recentInteractionWindow;
  final Duration exitWindow;
  final Duration exitObservation;
}

class AdPolicyDecision {
  const AdPolicyDecision({
    required this.shouldAttempt,
    required this.reason,
    required this.deckNumberToday,
    required this.shownCountSession,
    required this.shownCountDay,
  });

  final bool shouldAttempt;
  final AdPolicyDenialReason reason;
  final int deckNumberToday;
  final int shownCountSession;
  final int shownCountDay;

  bool get isFrequencyCapped => reason.isFrequencyProtection;
}

class AdExitObservation {
  const AdExitObservation({
    required this.placement,
    required this.observationId,
  });

  final AdPlacement placement;
  final String observationId;
}

typedef AdPolicyClock = DateTime Function();

/// Persisted, provider-neutral policy for the sole approved interstitial edge.
///
/// A deck completion is counted once by [completionId]. Eligibility is decided
/// only at that durable boundary. Inventory loading is deliberately separate so
/// an unavailable ad can never hold recommendation UI open.
class AdPolicyController {
  AdPolicyController({
    required this.sessionId,
    AdPolicyStorage? storage,
    AdPolicyClock? clock,
    this.config = const AdPolicyConfig(),
  })  : _storage = storage ?? const SecureAdPolicyStorage(),
        _clock = clock ?? DateTime.now;

  static const storageKey = 'adPolicyV2';
  static const legacyStorageKey = 'adPolicyV1';
  static const _schemaVersion = 2;
  static const _completionHistoryLimit = 32;

  final String sessionId;
  final AdPolicyStorage _storage;
  final AdPolicyClock _clock;
  final AdPolicyConfig config;

  Future<void>? _initialization;
  bool _initialized = false;
  bool _premium = true;
  bool _isFirstSession = true;
  int _sessionsStarted = 0;
  String? _activeSessionId;
  DateTime? _lastShownAtUtc;
  int _shownCountSession = 0;
  int _shownCountDay = 0;
  int _completedDeckCountDay = 0;
  String? _dayBucket;
  DateTime? _lastMonetizationInteractionAtUtc;
  String? _lastMonetizationInteractionType;
  final List<String> _recentCompletionIds = <String>[];
  AdPlacement? _pendingPlacement;
  String? _pendingCompletionId;
  AdPlacement? _closedPlacement;
  String? _closedObservationId;
  DateTime? _lastClosedAtUtc;
  DateTime? _backgroundedAtUtc;

  int get shownCountSession => _shownCountSession;
  int get shownCountDay => _shownCountDay;
  int get completedDeckCountDay => _completedDeckCountDay;
  bool get isFirstSession => _isFirstSession;
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

    final initialization = _restoreAndStartSession();
    _initialization = initialization;
    try {
      await initialization;
      _initialized = true;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _restoreAndStartSession() async {
    final encoded = await _storage.read(storageKey);
    var restored = false;
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map && decoded['schemaVersion'] == _schemaVersion) {
          final state = Map<String, dynamic>.from(decoded);
          _sessionsStarted = _nonNegativeInt(state['sessionsStarted']);
          _activeSessionId = state['activeSessionId'] as String?;
          _lastShownAtUtc = _date(state['lastShownAtUtc']);
          _shownCountSession = _nonNegativeInt(state['shownCountSession']);
          _shownCountDay = _nonNegativeInt(state['shownCountDay']);
          _completedDeckCountDay =
              _nonNegativeInt(state['completedDeckCountDay']);
          _dayBucket = state['dayBucket'] as String?;
          _lastMonetizationInteractionAtUtc =
              _date(state['lastMonetizationInteractionAtUtc']);
          _lastMonetizationInteractionType =
              state['lastMonetizationInteractionType'] as String?;
          final completionIds = state['recentCompletionIds'];
          if (completionIds is List) {
            _recentCompletionIds.addAll(
              completionIds.whereType<String>().where((id) => id.isNotEmpty),
            );
          }
          _pendingPlacement =
              AdPlacement.fromWireName(state['pendingPlacement'] as String?);
          _pendingCompletionId = state['pendingCompletionId'] as String?;
          _closedPlacement =
              AdPlacement.fromWireName(state['closedPlacement'] as String?);
          _closedObservationId = state['closedObservationId'] as String?;
          _lastClosedAtUtc = _date(state['lastClosedAtUtc']);
          _backgroundedAtUtc = _date(state['backgroundedAtUtc']);
          restored = true;
        }
      } catch (_) {
        restored = false;
      }
    }

    if (!restored) {
      _resetState();
    }

    // V1 counted arbitrary actions and used an incompatible 24-hour model.
    // It is intentionally retired instead of being interpreted as deck state.
    await _storage.delete(legacyStorageKey);
    _refreshDailyState();
    if (_activeSessionId != sessionId) {
      _isFirstSession = _sessionsStarted == 0;
      _sessionsStarted++;
      _activeSessionId = sessionId;
      _shownCountSession = 0;
      _pendingPlacement = null;
      _pendingCompletionId = null;
    } else {
      _isFirstSession = _sessionsStarted <= 1;
    }
    await _persist();
  }

  void _resetState() {
    _sessionsStarted = 0;
    _activeSessionId = null;
    _lastShownAtUtc = null;
    _shownCountSession = 0;
    _shownCountDay = 0;
    _completedDeckCountDay = 0;
    _dayBucket = null;
    _lastMonetizationInteractionAtUtc = null;
    _lastMonetizationInteractionType = null;
    _recentCompletionIds.clear();
    _pendingPlacement = null;
    _pendingCompletionId = null;
    _closedPlacement = null;
    _closedObservationId = null;
    _lastClosedAtUtc = null;
    _backgroundedAtUtc = null;
  }

  Future<void> setPremium(bool value) async {
    _premium = value;
    await initialize();
    if (value && (_pendingPlacement != null || _pendingCompletionId != null)) {
      _pendingPlacement = null;
      _pendingCompletionId = null;
      await _persist();
    }
  }

  Future<bool> shouldPreloadForNextCompletion({
    required bool isPremium,
  }) async {
    await initialize();
    _refreshDailyState();
    final nextDeckNumber = _completedDeckCountDay + 1;
    final reason = _structuralDenialReason(
      isPremium: isPremium,
      deckNumberToday: nextDeckNumber,
    );
    await _persist();
    return reason == AdPolicyDenialReason.none;
  }

  Future<AdPolicyDecision> recordDeckCompleted(
    AdPlacement placement, {
    required String completionId,
    required bool isPremium,
    required bool isForeground,
    required bool consentGranted,
    required bool inventoryReady,
  }) async {
    await initialize();
    _refreshDailyState();
    _premium = isPremium;

    if (completionId.isEmpty || _recentCompletionIds.contains(completionId)) {
      return _decision(AdPolicyDenialReason.duplicateCompletion);
    }

    _recentCompletionIds.add(completionId);
    if (_recentCompletionIds.length > _completionHistoryLimit) {
      _recentCompletionIds.removeRange(
        0,
        _recentCompletionIds.length - _completionHistoryLimit,
      );
    }
    _completedDeckCountDay++;

    var reason = _structuralDenialReason(
      isPremium: isPremium,
      deckNumberToday: _completedDeckCountDay,
    );
    if (reason == AdPolicyDenialReason.none && !isForeground) {
      reason = AdPolicyDenialReason.notForeground;
    }
    if (reason == AdPolicyDenialReason.none && !consentGranted) {
      reason = AdPolicyDenialReason.consentUnavailable;
    }
    if (reason == AdPolicyDenialReason.none && !inventoryReady) {
      reason = AdPolicyDenialReason.inventoryNotReady;
    }

    if (reason == AdPolicyDenialReason.none) {
      _pendingPlacement = placement;
      _pendingCompletionId = completionId;
    } else {
      _pendingPlacement = null;
      _pendingCompletionId = null;
    }
    await _persist();
    return _decision(reason);
  }

  AdPolicyDenialReason _structuralDenialReason({
    required bool isPremium,
    required int deckNumberToday,
  }) {
    if (_premium || isPremium) {
      return AdPolicyDenialReason.premium;
    }
    if (!config.enabled || config.maxPerSession <= 0 || config.maxPerDay <= 0) {
      return AdPolicyDenialReason.disabled;
    }
    if (_isFirstSession && !config.firstSessionEnabled) {
      return AdPolicyDenialReason.firstSession;
    }
    if (deckNumberToday == 1 && !config.firstDeckOfDayEnabled) {
      return AdPolicyDenialReason.firstDeckOfDay;
    }
    if (_shownCountSession >= config.maxPerSession) {
      return AdPolicyDenialReason.sessionCap;
    }
    if (_shownCountDay >= config.maxPerDay) {
      return AdPolicyDenialReason.dayCap;
    }
    final now = _clock().toUtc();
    final lastShownAt = _lastShownAtUtc;
    if (lastShownAt != null && now.isBefore(lastShownAt.add(config.cooldown))) {
      return AdPolicyDenialReason.cooldown;
    }
    final lastInteraction = _lastMonetizationInteractionAtUtc;
    if (lastInteraction != null &&
        now.isBefore(lastInteraction.add(config.recentInteractionWindow))) {
      return AdPolicyDenialReason.recentMonetization;
    }
    return AdPolicyDenialReason.none;
  }

  AdPolicyDecision _decision(AdPolicyDenialReason reason) => AdPolicyDecision(
        shouldAttempt: reason == AdPolicyDenialReason.none,
        reason: reason,
        deckNumberToday: _completedDeckCountDay,
        shownCountSession: _shownCountSession,
        shownCountDay: _shownCountDay,
      );

  Future<bool> shouldShowNow({
    required bool isPremium,
    required bool isForeground,
    required bool consentGranted,
    required bool inventoryReady,
  }) async {
    await initialize();
    _refreshDailyState();
    if (_pendingPlacement == null || _pendingCompletionId == null) {
      return false;
    }
    return _structuralDenialReason(
              isPremium: isPremium,
              deckNumberToday: _completedDeckCountDay,
            ) ==
            AdPolicyDenialReason.none &&
        isForeground &&
        consentGranted &&
        inventoryReady;
  }

  Future<bool> markShown(AdPlacement placement) async {
    await initialize();
    if (_pendingPlacement != placement || _pendingCompletionId == null) {
      return false;
    }
    final now = _clock().toUtc();
    _refreshDailyState();
    _lastShownAtUtc = now;
    _lastMonetizationInteractionAtUtc = now;
    _lastMonetizationInteractionType =
        MonetizationInteraction.interstitial.wireName;
    _shownCountSession++;
    _shownCountDay++;
    _pendingPlacement = null;
    _pendingCompletionId = null;
    await _persist();
    return true;
  }

  Future<void> cancelPending(AdPlacement placement) async {
    await initialize();
    if (_pendingPlacement != placement) {
      return;
    }
    _pendingPlacement = null;
    _pendingCompletionId = null;
    await _persist();
  }

  Future<void> recordMonetizationInteraction(
    MonetizationInteraction interaction,
  ) async {
    await initialize();
    _lastMonetizationInteractionAtUtc = _clock().toUtc();
    _lastMonetizationInteractionType = interaction.wireName;
    await _persist();
  }

  Future<void> markClosed(
    AdPlacement placement, {
    String? observationId,
  }) async {
    await initialize();
    _lastClosedAtUtc = _clock().toUtc();
    _closedPlacement = placement;
    _closedObservationId = observationId;
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
    _closedObservationId = null;
    _backgroundedAtUtc = null;
    await _persist();
  }

  Future<AdPlacement?> consumeExitIfQualified() async {
    return (await consumeExitObservationIfQualified())?.placement;
  }

  Future<AdExitObservation?> consumeExitObservationIfQualified() async {
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
    final observationId = _closedObservationId;
    _lastClosedAtUtc = null;
    _backgroundedAtUtc = null;
    _closedPlacement = null;
    _closedObservationId = null;
    await _persist();
    if (placement == null) {
      return null;
    }
    return AdExitObservation(
      placement: placement,
      observationId: observationId == null || observationId.isEmpty
          ? 'legacy-${closedAt.microsecondsSinceEpoch}'
          : observationId,
    );
  }

  void _refreshDailyState() {
    final bucket = _clock().toUtc().toIso8601String().substring(0, 10);
    if (_dayBucket == bucket) {
      return;
    }
    _dayBucket = bucket;
    _shownCountDay = 0;
    _completedDeckCountDay = 0;
  }

  Future<void> _persist() {
    return _storage.write(
      storageKey,
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'sessionsStarted': _sessionsStarted,
        'activeSessionId': _activeSessionId,
        'lastShownAtUtc': _lastShownAtUtc?.toIso8601String(),
        'shownCountSession': _shownCountSession,
        'shownCountDay': _shownCountDay,
        'completedDeckCountDay': _completedDeckCountDay,
        'dayBucket': _dayBucket,
        'lastMonetizationInteractionAtUtc':
            _lastMonetizationInteractionAtUtc?.toIso8601String(),
        'lastMonetizationInteractionType': _lastMonetizationInteractionType,
        'recentCompletionIds': _recentCompletionIds,
        'pendingPlacement': _pendingPlacement?.wireName,
        'pendingCompletionId': _pendingCompletionId,
        'closedPlacement': _closedPlacement?.wireName,
        'closedObservationId': _closedObservationId,
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
