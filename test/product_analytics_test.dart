import 'package:flutter_test/flutter_test.dart';
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
          'interstitial_shown',
          'interstitial_closed',
          'user_exit_after_ad',
        ]));
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
