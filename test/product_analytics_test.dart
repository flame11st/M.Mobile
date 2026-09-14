import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Objects/recommendation_discovery_session.dart';
import 'package:mmobile/Services/product_analytics.dart';

void main() {
  late _MemoryAnalyticsStorage storage;
  late _FakeAnalyticsTransport transport;
  late int idCounter;

  String idFactory(String prefix) {
    idCounter += 1;
    return '${prefix}_${idCounter.toRadixString(16).padLeft(32, '0')}';
  }

  ProductAnalytics createAnalytics({bool succeeds = false}) {
    transport = _FakeAnalyticsTransport(succeeds: succeeds);
    return ProductAnalytics(
      storage: storage,
      transport: transport,
      clock: () => DateTime.utc(2026, 8, 15, 5),
      idFactory: idFactory,
      recordAppOpen: false,
    );
  }

  setUp(() {
    storage = _MemoryAnalyticsStorage();
    idCounter = 0;
  });

  test('typed contract contains every required event exactly once', () {
    final names = ProductAnalyticsEventName.values
        .map((event) => event.wireName)
        .toList(growable: false);

    expect(names.toSet().length, names.length);
    expect(
        names,
        containsAll(<String>[
          'app_open',
          'onboarding_started',
          'onboarding_skipped',
          'rating_started',
          'movie_rated',
          'rating_5_complete',
          'rating_10_complete',
          'discover_viewed',
          'moviedna_expanded',
          'recommendation_started',
          'recommendation_generated',
          'recommendation_viewed',
          'recommendation_watchlist_added',
          'recommendation_seen_already',
          'recommendation_details_opened',
          'recommendation_deck_completed',
          'watchlist_added',
          'watchlist_removed',
          'mark_watched_started',
          'mark_watched_completed',
          'movie_rating_changed',
          'search_started',
          'search_success',
          'search_no_results',
          'where_to_watch_viewed',
          'where_to_watch_clicked',
          'personal_list_created',
          'personal_list_item_added',
          'sign_in_started',
          'sign_in_completed',
          'premium_viewed',
          'premium_started',
          'premium_completed',
          'native_ad_eligible',
          'native_ad_impression',
          'native_ad_clicked',
          'native_ad_failed',
          'interstitial_eligible',
          'interstitial_loaded',
          'interstitial_shown',
          'interstitial_closed',
          'interstitial_failed',
          'interstitial_skipped_frequency_cap',
          'interstitial_skipped_not_loaded',
          'rewarded_offer_shown',
          'rewarded_started',
          'rewarded_completed',
          'rewarded_dismissed',
          'rewarded_failed',
          'rewarded_credit_granted',
          'rewarded_credit_consumed',
          'rewarded_credit_restored',
          'recommendation_free_deck_used',
          'recommendation_limit_reached',
          'recommendation_allowance_config_resolved',
          'premium_offer_shown',
          'premium_purchase_started',
          'premium_purchase_completed',
          'premium_purchase_failed',
          'premium_restored',
          'ad_revenue_paid',
          'user_exit_after_ad',
        ]));
  });

  test('monetization contract requires privacy-safe contexts', () async {
    final analytics = createAnalytics();
    await analytics.initialize();

    expect(
      await analytics.track(
        ProductAnalyticsEventName.nativeAdImpression,
        parameters: const {
          ProductAnalyticsParameter.placement: 'discover_native',
          ProductAnalyticsParameter.isPremium: false,
          ProductAnalyticsParameter.movieId: 42,
        },
        transitionId: 'native-1',
      ),
      isFalse,
    );
    expect(
      await analytics.track(
        ProductAnalyticsEventName.interstitialShown,
        parameters: const {
          ProductAnalyticsParameter.placement: 'recommendation_completion',
          ProductAnalyticsParameter.isPremium: false,
        },
        transitionId: 'interstitial-1',
      ),
      isFalse,
    );
    expect(analytics.queuedEvents, isEmpty);
  });

  test('completion and credit callbacks enqueue exactly once', () async {
    final analytics = createAnalytics();
    await analytics.initialize();
    const parameters = {
      ProductAnalyticsParameter.placement: 'extra_recommendation_rewarded',
      ProductAnalyticsParameter.isPremium: false,
    };

    expect(
      await analytics.track(
        ProductAnalyticsEventName.rewardedCreditGranted,
        parameters: parameters,
      ),
      isFalse,
    );
    expect(
      await analytics.track(
        ProductAnalyticsEventName.rewardedCreditGranted,
        parameters: parameters,
        transitionId: 'reward-callback-1',
      ),
      isTrue,
    );
    expect(
      await analytics.track(
        ProductAnalyticsEventName.rewardedCreditGranted,
        parameters: parameters,
        transitionId: 'reward-callback-1',
      ),
      isFalse,
    );
    expect(analytics.queuedEvents, hasLength(1));
  });

  test('durable reward ledger transitions emit after authority exactly once',
      () async {
    final analytics = createAnalytics();
    const allowance = RecommendationAllowance(
      limitReached: false,
      isPremium: false,
      meteringAvailable: true,
      freeDecksPerDay: 2,
      freeDecksUsed: 2,
      freeDecksRemaining: 0,
      rewardedDecksGranted: 1,
      rewardedDecksUsed: 1,
      resetAtUtc: null,
      rewardedCreditTransitions: [
        RewardedDeckCreditTransition(
          transitionId: '11111111-1111-5111-8111-111111111111',
          type: 'granted',
          occurredAtUtc: null,
        ),
        RewardedDeckCreditTransition(
          transitionId: '22222222-2222-5222-8222-222222222222',
          type: 'consumed',
          occurredAtUtc: null,
        ),
        RewardedDeckCreditTransition(
          transitionId: '33333333-3333-5333-8333-333333333333',
          type: 'restored',
          occurredAtUtc: null,
        ),
      ],
    );

    await trackRewardedCreditTransitions(allowance, analytics: analytics);
    await trackRewardedCreditTransitions(allowance, analytics: analytics);

    expect(analytics.queuedEvents, hasLength(3));
    expect(
      analytics.queuedEvents.map((event) => event['name']),
      containsAll([
        'rewarded_credit_granted',
        'rewarded_credit_consumed',
        'rewarded_credit_restored',
      ]),
    );
  });

  test('allowance configuration outcome is privacy-safe and exactly once',
      () async {
    final analytics = createAnalytics();
    const allowance = RecommendationAllowance(
      limitReached: false,
      isPremium: false,
      meteringEnabled: false,
      meteringAvailable: true,
      rolloutConfigurationAvailable: false,
      rolloutConfigurationSchemaVersion: 0,
      rolloutConfigurationOutcome: 'remote_unavailable',
      freeDecksPerDay: 2,
      freeDecksUsed: 2,
      freeDecksRemaining: 0,
      resetAtUtc: null,
    );

    await trackRecommendationAllowanceConfiguration(
      allowance,
      analytics: analytics,
    );
    await trackRecommendationAllowanceConfiguration(
      allowance,
      analytics: analytics,
    );

    expect(analytics.queuedEvents, hasLength(1));
    expect(
      analytics.queuedEvents.single['name'],
      'recommendation_allowance_config_resolved',
    );
    expect(
      analytics.queuedEvents.single['parameters'],
      {
        'metering_enabled': false,
        'rollout_configuration_available': false,
        'rollout_configuration_schema_version': 0,
        'rollout_configuration_outcome': 'remote_unavailable',
      },
    );
  });

  test('every monetization event declares required contexts', () {
    expect(
      MonetizationAnalyticsContract.requiredParameters.keys.toSet(),
      MonetizationAnalyticsContract.eventNames,
    );
    expect(
      MonetizationAnalyticsContract.allowedParameters,
      isNot(contains(ProductAnalyticsParameter.movieId)),
    );
    expect(
      MonetizationAnalyticsContract.allowedParameters,
      isNot(contains(ProductAnalyticsParameter.opinionState)),
    );
  });

  test('offline queue survives restart and drains with original event IDs',
      () async {
    final first = createAnalytics();
    await first.initialize();
    await first.track(
      ProductAnalyticsEventName.movieRated,
      parameters: const {
        ProductAnalyticsParameter.movieId:
            '12345678-1234-1234-1234-123456789012',
        ProductAnalyticsParameter.opinionState: 'liked',
      },
      transitionId: 'rating-1',
    );
    final queuedId = first.queuedEvents.single['eventId'];
    expect(
      queuedId,
      matches(RegExp(
        r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
      )),
    );

    final second = createAnalytics(succeeds: true);
    await second.initialize();
    expect(await second.flush(), isTrue);

    expect(transport.sentEvents, hasLength(1));
    expect(transport.sentEvents.single['eventId'], queuedId);
    expect(second.queuedEvents, isEmpty);
  });

  test('transition IDs prevent optimistic and retry duplicate emission',
      () async {
    final analytics = createAnalytics();
    await analytics.initialize();

    expect(
      await analytics.track(
        ProductAnalyticsEventName.watchlistAdded,
        transitionId: 'movie-1:list-1',
      ),
      isTrue,
    );
    expect(
      await analytics.track(
        ProductAnalyticsEventName.watchlistAdded,
        transitionId: 'movie-1:list-1',
      ),
      isFalse,
    );
    expect(analytics.queuedEvents, hasLength(1));
  });

  test('identity transition links only future events', () async {
    final analytics = createAnalytics();
    await analytics.initialize();
    await analytics.track(ProductAnalyticsEventName.appOpen);
    await analytics.setAuthenticatedUser(
      '12345678-1234-1234-1234-1234567890ab',
    );
    await analytics.track(ProductAnalyticsEventName.signInCompleted);

    expect(analytics.queuedEvents.first['userPseudonymousId'], isNull);
    expect(
      analytics.queuedEvents.last['userPseudonymousId'],
      'u_123456781234123412341234567890ab',
    );
  });

  test('sensitive or free-form values are rejected without throwing', () async {
    final analytics = createAnalytics();
    await analytics.initialize();

    expect(
      await analytics.track(
        ProductAnalyticsEventName.searchSuccess,
        parameters: const {
          ProductAnalyticsParameter.sourceSurface: 'person@example.com',
        },
      ),
      isFalse,
    );
    expect(analytics.queuedEvents, isEmpty);
  });

  test('queue remains bounded while delivery is unavailable', () async {
    transport = _FakeAnalyticsTransport(succeeds: false);
    final analytics = ProductAnalytics(
      storage: storage,
      transport: transport,
      clock: () => DateTime.utc(2026, 8, 15, 5),
      idFactory: idFactory,
      recordAppOpen: false,
      maxQueueSize: 3,
    );
    await analytics.initialize();

    for (var index = 0; index < 5; index++) {
      await analytics.track(
        ProductAnalyticsEventName.discoverViewed,
        parameters: {
          ProductAnalyticsParameter.position: index,
        },
      );
    }

    expect(analytics.queuedEvents, hasLength(3));
    expect(
      analytics.queuedEvents
          .map((event) => event['parameters']['position'])
          .toList(),
      [2, 3, 4],
    );
  });
}

class _MemoryAnalyticsStorage implements ProductAnalyticsStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _FakeAnalyticsTransport implements ProductAnalyticsTransport {
  _FakeAnalyticsTransport({required this.succeeds});

  final bool succeeds;
  final List<Map<String, dynamic>> sentEvents = [];

  @override
  Future<bool> send(List<Map<String, dynamic>> events) async {
    if (!succeeds) {
      return false;
    }
    sentEvents.addAll(events);
    return true;
  }
}
