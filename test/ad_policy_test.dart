import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Helpers/ad_policy.dart';

void main() {
  test('first app session is protected even with ready inventory', () async {
    final policy = _policy(
      storage: _MemoryAdPolicyStorage(),
      sessionId: 'session-1',
    );

    final decision = await _complete(policy, 'deck-1');

    expect(decision.shouldAttempt, isFalse);
    expect(decision.reason, AdPolicyDenialReason.firstSession);
    expect(decision.deckNumberToday, 1);
  });

  test('first completed deck of each UTC day is protected', () async {
    final storage = _MemoryAdPolicyStorage();
    var now = DateTime.utc(2026, 8, 24, 12);
    await _policy(
      storage: storage,
      sessionId: 'session-1',
      clock: () => now,
    ).initialize();
    final secondSession = _policy(
      storage: storage,
      sessionId: 'session-2',
      clock: () => now,
    );

    expect(
      (await _complete(secondSession, 'deck-1')).reason,
      AdPolicyDenialReason.firstDeckOfDay,
    );
    expect((await _complete(secondSession, 'deck-2')).shouldAttempt, isTrue);

    now = DateTime.utc(2026, 8, 25, 0, 1);
    expect(
      (await _complete(secondSession, 'deck-next-day')).reason,
      AdPolicyDenialReason.firstDeckOfDay,
    );
  });

  test('cooldown rejects 9:59 and accepts exactly 10:00', () async {
    var now = DateTime.utc(2026, 8, 24, 12);
    final policy = _policy(
      storage: _MemoryAdPolicyStorage(),
      sessionId: 'session-1',
      clock: () => now,
      config: _unprotectedConfig(),
    );

    expect((await _complete(policy, 'deck-1')).shouldAttempt, isTrue);
    expect(
      await policy.markShown(AdPlacement.recommendationCompletion),
      isTrue,
    );

    now = now.add(const Duration(minutes: 9, seconds: 59));
    expect(
      (await _complete(policy, 'deck-2')).reason,
      AdPolicyDenialReason.cooldown,
    );

    now = now.add(const Duration(seconds: 1));
    expect((await _complete(policy, 'deck-3')).shouldAttempt, isTrue);
  });

  test('two per session and three per UTC day caps are enforced', () async {
    var now = DateTime.utc(2026, 8, 24, 12);
    final sessionStorage = _MemoryAdPolicyStorage();
    final sessionPolicy = _policy(
      storage: sessionStorage,
      sessionId: 'session-1',
      clock: () => now,
      config: _unprotectedConfig(
        cooldown: Duration.zero,
        recentInteractionWindow: Duration.zero,
      ),
    );

    for (var index = 0; index < 2; index++) {
      expect(
        (await _complete(sessionPolicy, 'session-deck-$index')).shouldAttempt,
        isTrue,
      );
      await sessionPolicy.markShown(AdPlacement.recommendationCompletion);
    }
    expect(
      (await _complete(sessionPolicy, 'session-deck-3')).reason,
      AdPolicyDenialReason.sessionCap,
    );

    final dayStorage = _MemoryAdPolicyStorage();
    final dayPolicy = _policy(
      storage: dayStorage,
      sessionId: 'session-1',
      clock: () => now,
      config: _unprotectedConfig(
        maxPerSession: 10,
        cooldown: Duration.zero,
        recentInteractionWindow: Duration.zero,
      ),
    );
    for (var index = 0; index < 3; index++) {
      expect(
        (await _complete(dayPolicy, 'day-deck-$index')).shouldAttempt,
        isTrue,
      );
      await dayPolicy.markShown(AdPlacement.recommendationCompletion);
    }
    expect(
      (await _complete(dayPolicy, 'day-deck-4')).reason,
      AdPolicyDenialReason.dayCap,
    );

    now = DateTime.utc(2026, 8, 25);
    expect((await _complete(dayPolicy, 'next-day')).shouldAttempt, isTrue);
  });

  for (final interaction in const [
    MonetizationInteraction.nativeAd,
    MonetizationInteraction.rewardedAd,
    MonetizationInteraction.premiumPrompt,
  ]) {
    test('${interaction.wireName} blocks a back-to-back interstitial',
        () async {
      var now = DateTime.utc(2026, 8, 24, 12);
      final policy = _policy(
        storage: _MemoryAdPolicyStorage(),
        sessionId: 'session-1',
        clock: () => now,
        config: _unprotectedConfig(),
      );
      await policy.recordMonetizationInteraction(interaction);

      expect(
        (await _complete(policy, 'deck-1')).reason,
        AdPolicyDenialReason.recentMonetization,
      );

      now = now.add(const Duration(minutes: 10));
      expect((await _complete(policy, 'deck-2')).shouldAttempt, isTrue);
    });
  }

  test('Premium, disabled config, and unavailable inventory fail closed',
      () async {
    final premium = _policy(
      storage: _MemoryAdPolicyStorage(),
      sessionId: 'premium',
      config: _unprotectedConfig(),
    );
    expect(
      (await _complete(premium, 'premium-deck', isPremium: true)).reason,
      AdPolicyDenialReason.premium,
    );

    final disabled = _policy(
      storage: _MemoryAdPolicyStorage(),
      sessionId: 'disabled',
      config: const AdPolicyConfig(enabled: false),
    );
    expect(
      (await _complete(disabled, 'disabled-deck')).reason,
      AdPolicyDenialReason.disabled,
    );

    final unloaded = _policy(
      storage: _MemoryAdPolicyStorage(),
      sessionId: 'unloaded',
      config: _unprotectedConfig(),
    );
    final decision = await _complete(
      unloaded,
      'unloaded-deck',
      inventoryReady: false,
    );
    expect(decision.reason, AdPolicyDenialReason.inventoryNotReady);
    expect(unloaded.pendingPlacement, isNull);
  });

  test('duplicate completion is persisted and counted exactly once', () async {
    final storage = _MemoryAdPolicyStorage();
    final firstProcess = _policy(
      storage: storage,
      sessionId: 'session-1',
      config: _unprotectedConfig(),
    );
    expect((await _complete(firstProcess, 'deck-1')).shouldAttempt, isTrue);

    final recreated = _policy(
      storage: storage,
      sessionId: 'session-1',
      config: _unprotectedConfig(),
    );
    final duplicate = await _complete(recreated, 'deck-1');
    expect(duplicate.reason, AdPolicyDenialReason.duplicateCompletion);
    expect(duplicate.deckNumberToday, 1);
    expect(recreated.pendingPlacement, AdPlacement.recommendationCompletion);
  });

  test('legacy arbitrary-action state is retired without migration', () async {
    final storage = _MemoryAdPolicyStorage()
      ..values[AdPolicyController.legacyStorageKey] = jsonEncode({
        'completedActions': 99,
        'lastShownAtUtc': DateTime.utc(2026).toIso8601String(),
      });
    final policy = _policy(
      storage: storage,
      sessionId: 'session-1',
      config: _unprotectedConfig(),
    );

    await policy.initialize();

    expect(storage.values.containsKey(AdPolicyController.legacyStorageKey),
        isFalse);
    expect(policy.completedDeckCountDay, 0);
    expect(storage.values[AdPolicyController.storageKey], isNotNull);
  });

  test('foreground and consent are revalidated before showing', () async {
    final policy = _policy(
      storage: _MemoryAdPolicyStorage(),
      sessionId: 'session-1',
      config: _unprotectedConfig(),
    );
    await _complete(policy, 'deck-1');

    expect(
      await policy.shouldShowNow(
        isPremium: false,
        isForeground: false,
        consentGranted: true,
        inventoryReady: true,
      ),
      isFalse,
    );
    expect(
      await policy.shouldShowNow(
        isPremium: false,
        isForeground: true,
        consentGranted: false,
        inventoryReady: true,
      ),
      isFalse,
    );
    expect(
      await policy.shouldShowNow(
        isPremium: false,
        isForeground: true,
        consentGranted: true,
        inventoryReady: true,
      ),
      isTrue,
    );
  });

  test('post-ad exit observation survives recreation and consumes once',
      () async {
    var now = DateTime.utc(2026, 8, 24, 12);
    final storage = _MemoryAdPolicyStorage();
    final first = _policy(
      storage: storage,
      sessionId: 'session-1',
      clock: () => now,
    );
    await first.markClosed(
      AdPlacement.recommendationCompletion,
      observationId: 'interstitial-attempt-1',
    );
    now = now.add(const Duration(seconds: 5));
    await first.markBackgrounded();
    now = now.add(const Duration(seconds: 15));

    final recreated = _policy(
      storage: storage,
      sessionId: 'session-1',
      clock: () => now,
    );
    final observation = await recreated.consumeExitObservationIfQualified();
    expect(observation?.placement, AdPlacement.recommendationCompletion);
    expect(observation?.observationId, 'interstitial-attempt-1');
    expect(await recreated.consumeExitObservationIfQualified(), isNull);
  });

  test('foreground return clears the post-ad exit candidate', () async {
    var now = DateTime.utc(2026, 8, 24, 12);
    final policy = _policy(
      storage: _MemoryAdPolicyStorage(),
      sessionId: 'session-1',
      clock: () => now,
    );
    await policy.markClosed(AdPlacement.recommendationCompletion);
    now = now.add(const Duration(seconds: 5));
    await policy.markBackgrounded();
    await policy.markResumed();
    now = now.add(const Duration(seconds: 20));

    expect(await policy.consumeExitIfQualified(), isNull);
  });
}

AdPolicyController _policy({
  required _MemoryAdPolicyStorage storage,
  required String sessionId,
  DateTime Function()? clock,
  AdPolicyConfig config = const AdPolicyConfig(),
}) {
  return AdPolicyController(
    storage: storage,
    sessionId: sessionId,
    clock: clock,
    config: config,
  );
}

AdPolicyConfig _unprotectedConfig({
  Duration cooldown = const Duration(minutes: 10),
  Duration recentInteractionWindow = const Duration(minutes: 10),
  int maxPerSession = 2,
  int maxPerDay = 3,
}) {
  return AdPolicyConfig(
    firstSessionEnabled: true,
    firstDeckOfDayEnabled: true,
    cooldown: cooldown,
    recentInteractionWindow: recentInteractionWindow,
    maxPerSession: maxPerSession,
    maxPerDay: maxPerDay,
  );
}

Future<AdPolicyDecision> _complete(
  AdPolicyController policy,
  String id, {
  bool isPremium = false,
  bool isForeground = true,
  bool consentGranted = true,
  bool inventoryReady = true,
}) {
  return policy.recordDeckCompleted(
    AdPlacement.recommendationCompletion,
    completionId: id,
    isPremium: isPremium,
    isForeground: isForeground,
    consentGranted: consentGranted,
    inventoryReady: inventoryReady,
  );
}

class _MemoryAdPolicyStorage implements AdPolicyStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
