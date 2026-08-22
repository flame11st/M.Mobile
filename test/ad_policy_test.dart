import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Helpers/ad_policy.dart';

void main() {
  test('free policy waits for four completed decks and enforces cooldown',
      () async {
    var now = DateTime.utc(2026, 8, 21, 12);
    final policy = AdPolicyController(
      storage: _MemoryAdPolicyStorage(),
      clock: () => now,
      config: const AdPolicyConfig(
        completedActionThreshold: 4,
        cooldown: Duration(hours: 24),
      ),
    );

    for (var index = 0; index < 3; index++) {
      final decision = await policy.recordCompletedAction(
        AdPlacement.recommendationCompletion,
        isPremium: false,
      );
      expect(decision.shouldAttempt, isFalse);
      expect(decision.actionsUntilEligible, 3 - index);
    }

    final eligible = await policy.recordCompletedAction(
      AdPlacement.recommendationCompletion,
      isPremium: false,
    );
    expect(eligible.shouldAttempt, isTrue);
    expect(
      await policy.shouldShowNow(
        isPremium: false,
        isForeground: true,
        consentGranted: true,
        inventoryReady: true,
      ),
      isTrue,
    );
    expect(
      await policy.shouldShowNow(
        isPremium: false,
        isForeground: false,
        consentGranted: true,
        inventoryReady: true,
      ),
      isFalse,
    );

    await policy.markShown(AdPlacement.recommendationCompletion);
    now = now.add(const Duration(hours: 1));
    AdPolicyDecision? duringCooldown;
    for (var index = 0; index < 4; index++) {
      duringCooldown = await policy.recordCompletedAction(
        AdPlacement.recommendationCompletion,
        isPremium: false,
      );
    }
    expect(duringCooldown!.shouldAttempt, isFalse);

    now = now.add(const Duration(hours: 23));
    final afterCooldown = await policy.recordCompletedAction(
      AdPlacement.recommendationCompletion,
      isPremium: false,
    );
    expect(afterCooldown.shouldAttempt, isTrue);
  });

  test('premium clears pending eligibility and never attempts an ad', () async {
    final policy = AdPolicyController(
      storage: _MemoryAdPolicyStorage(),
      config: const AdPolicyConfig(completedActionThreshold: 1),
    );

    expect(
      (await policy.recordCompletedAction(
        AdPlacement.recommendationCompletion,
        isPremium: false,
      ))
          .shouldAttempt,
      isTrue,
    );

    await policy.setPremium(true);
    expect(policy.pendingPlacement, isNull);
    expect(policy.completedActions, 0);
    expect(
      (await policy.recordCompletedAction(
        AdPlacement.recommendationCompletion,
        isPremium: true,
      ))
          .shouldAttempt,
      isFalse,
    );
    expect(
      await policy.shouldShowNow(
        isPremium: true,
        isForeground: true,
        consentGranted: true,
        inventoryReady: true,
      ),
      isFalse,
    );
  });

  test(
      'unavailable inventory and process recreation do not consume eligibility',
      () async {
    final storage = _MemoryAdPolicyStorage();
    final firstProcess = AdPolicyController(
      storage: storage,
      config: const AdPolicyConfig(completedActionThreshold: 2),
    );

    await firstProcess.recordCompletedAction(
      AdPlacement.recommendationCompletion,
      isPremium: false,
    );

    final secondProcess = AdPolicyController(
      storage: storage,
      config: const AdPolicyConfig(completedActionThreshold: 2),
    );
    final eligible = await secondProcess.recordCompletedAction(
      AdPlacement.recommendationCompletion,
      isPremium: false,
    );
    expect(eligible.shouldAttempt, isTrue);
    expect(
      await secondProcess.shouldShowNow(
        isPremium: false,
        isForeground: true,
        consentGranted: true,
        inventoryReady: false,
      ),
      isFalse,
    );

    final thirdProcess = AdPolicyController(
      storage: storage,
      config: const AdPolicyConfig(completedActionThreshold: 2),
    );
    await thirdProcess.setPremium(false);
    expect(
      await thirdProcess.shouldShowNow(
        isPremium: false,
        isForeground: true,
        consentGranted: true,
        inventoryReady: true,
      ),
      isTrue,
    );
  });

  test('exit means background within 30 seconds and no return for 15 seconds',
      () async {
    var now = DateTime.utc(2026, 8, 21, 12);
    final storage = _MemoryAdPolicyStorage();
    final policy = AdPolicyController(
      storage: storage,
      clock: () => now,
      config: const AdPolicyConfig(
        exitWindow: Duration(seconds: 30),
        exitObservation: Duration(seconds: 15),
      ),
    );

    await policy.markClosed(AdPlacement.recommendationCompletion);
    now = now.add(const Duration(seconds: 10));
    await policy.markBackgrounded();
    now = now.add(const Duration(seconds: 14));
    expect(await policy.consumeExitIfQualified(), isNull);

    now = now.add(const Duration(seconds: 1));
    final recreatedProcess = AdPolicyController(
      storage: storage,
      clock: () => now,
      config: const AdPolicyConfig(
        exitWindow: Duration(seconds: 30),
        exitObservation: Duration(seconds: 15),
      ),
    );
    expect(
      await recreatedProcess.consumeExitIfQualified(),
      AdPlacement.recommendationCompletion,
    );
    expect(await recreatedProcess.consumeExitIfQualified(), isNull);
  });

  test('foreground return clears the post-ad exit candidate', () async {
    var now = DateTime.utc(2026, 8, 21, 12);
    final policy = AdPolicyController(
      storage: _MemoryAdPolicyStorage(),
      clock: () => now,
    );

    await policy.markClosed(AdPlacement.recommendationCompletion);
    now = now.add(const Duration(seconds: 5));
    await policy.markBackgrounded();
    now = now.add(const Duration(seconds: 5));
    await policy.markResumed();
    now = now.add(const Duration(seconds: 20));
    expect(await policy.consumeExitIfQualified(), isNull);
  });
}

class _MemoryAdPolicyStorage implements AdPolicyStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
