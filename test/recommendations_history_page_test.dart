import 'dart:convert';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/recommendations_history_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ServiceAgent.baseUrl = 'http://127.0.0.1:5000/';
    ServiceAgent.state = Object();
  });

  tearDown(() {
    FlutterSecureStorage.setMockInitialValues({});
    ServiceAgent.state = null;
  });

  testWidgets(
      'root groups sessions and detail preserves rank evidence and action',
      (tester) async {
    final user = await _userState();
    final service = _FakeHistoryService(
      pages: {
        0: _historyPage([
          _batch('batch-new', '2026-08-14T18:00:00Z', mode: 2),
          _batch('batch-old', '2026-08-13T18:00:00Z'),
        ]),
      },
      details: {
        'batch-new': _detail('batch-new'),
      },
    );

    await _pumpHistory(tester, user, service: service);

    expect(
      find.byKey(const Key('recommendation-history-batch-list')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('history-batch-batch-new')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('history-batch-batch-old')), findsOneWidget);
    expect(find.text('Aug 14, 2026'), findsOneWidget);
    expect(find.text('Adventurous'), findsOneWidget);
    expect(find.text('10 picks'), findsNWidgets(2));
    expect(find.text('Dune'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('history-batch-batch-new')));
    await tester.pumpAndSettle();

    expect(find.text('Adventurous Movies deck'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Arrival'), findsOneWidget);
    expect(find.text('Strong match'), findsOneWidget);
    expect(find.text('Good match'), findsOneWidget);
    expect(
      find.textContaining('Saved to Watchlist', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Rated Liked', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Why this pick'), findsNWidgets(2));
    expect(find.textContaining('Science Fiction overlap'), findsOneWidget);
    expect(find.textContaining('% match'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('root paginates older batches without duplicating cards',
      (tester) async {
    final user = await _userState();
    final service = _FakeHistoryService(
      pages: {
        0: _historyPage(
          [_batch('batch-1', '2026-08-14T18:00:00Z')],
          nextCursor: 1,
          hasMore: true,
        ),
        1: _historyPage(
          [_batch('batch-2', '2026-08-12T18:00:00Z')],
          nextCursor: 2,
        ),
      },
    );

    await _pumpHistory(tester, user, service: service);
    expect(find.byKey(const ValueKey('history-batch-batch-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('history-batch-batch-2')), findsNothing);

    await tester.tap(
      find.byKey(const Key('recommendation-history-load-more')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('history-batch-batch-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('history-batch-batch-2')), findsOneWidget);
    expect(service.requestedCursors, [0, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cached history remains truthful when refresh is offline',
      (tester) async {
    final user = await _userState();
    final cachedPage = _historyPage([
      _batch('cached-batch', '2026-08-10T18:00:00Z'),
    ]);
    final store = _MemoryHistoryStore({
      'recommendation_history_batches_v2_history-test-user':
          jsonEncode(cachedPage),
    });
    final service = _FakeHistoryService(throwOnRoot: true);

    await _pumpHistory(
      tester,
      user,
      service: service,
      store: store,
    );

    expect(
      find.byKey(const ValueKey('history-batch-cached-batch')),
      findsOneWidget,
    );
    expect(find.textContaining('Showing saved history'), findsOneWidget);
    expect(find.text('History unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text keeps batch hierarchy readable without overflow',
      (tester) async {
    final user = await _userState();
    final service = _FakeHistoryService(
      pages: {
        0: _historyPage([
          _batch('large-text', '2026-08-14T18:00:00Z', mode: 2),
        ]),
      },
    );

    await _pumpHistory(
      tester,
      user,
      service: service,
      size: const Size(430, 930),
      textScale: 1.3,
    );

    expect(find.text('Adventurous'), findsOneWidget);
    expect(find.text('10 picks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final configuration in [
    (size: const Size(390, 844), textScale: 1.0, name: '390x844 at 1.0x'),
    (size: const Size(430, 930), textScale: 1.3, name: '430x930 at 1.3x'),
  ]) {
    testWidgets(
      '${configuration.name} root and detail semantics expose one real activate action',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        final user = await _userState();
        final service = _FakeHistoryService(
          pages: {
            0: _historyPage([
              _batch('semantic-batch', '2026-08-14T18:00:00Z', mode: 2),
            ]),
          },
          details: {
            'semantic-batch': _detail('semantic-batch'),
          },
        );

        await _pumpHistory(
          tester,
          user,
          service: service,
          size: configuration.size,
          textScale: configuration.textScale,
        );

        const rootLabel =
            'Aug 14, 2026, Movies, Adventurous, 10 picks. Open deck.';
        final rootControl = find.semantics.byLabel(rootLabel);
        expect(rootControl, findsOne);
        final rootData = rootControl.evaluate().single.getSemanticsData();
        expect(rootData.flagsCollection.isButton, isTrue);
        expect(rootData.hasAction(SemanticsAction.tap), isTrue);

        tester.semantics.tap(rootControl);
        await tester.pumpAndSettle();

        const detailLabel =
            'Rank 1. Dune. Strong match. Its Science Fiction overlap connects directly to your like for Arrival. Saved to Watchlist. Open details.';
        final detailControl = find.semantics.byLabel(detailLabel);
        expect(detailControl, findsOne);
        final detailData = detailControl.evaluate().single.getSemanticsData();
        expect(detailData.flagsCollection.isButton, isTrue);
        expect(detailData.hasAction(SemanticsAction.tap), isTrue);
        expect(detailData.label, isNot(contains('..')));

        tester.semantics.tap(detailControl);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('movie-details-hero')), findsOneWidget);
        expect(tester.takeException(), isNull);
        semanticsHandle.dispose();
      },
    );
  }
}

Future<UserState> _userState() async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'history-access',
    'refreshToken': 'history-refresh',
    'userId': 'history-test-user',
    'isIncognitoMode': 'true',
  });
  final user = UserState(storage: const FlutterSecureStorage());
  await user.initialization;
  return user;
}

Future<void> _pumpHistory(
  WidgetTester tester,
  UserState user, {
  required _FakeHistoryService service,
  RecommendationHistoryStore? store,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final movies = MoviesState(storage: const FlutterSecureStorage());
  await movies.cacheInitialization;
  addTearDown(movies.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserState>.value(value: user),
        ChangeNotifierProvider<MoviesState>.value(value: movies),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: RecommendationsHistoryPage(
          serviceAgent: service,
          store: store ?? _MemoryHistoryStore(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeHistoryService extends ServiceAgent {
  _FakeHistoryService({
    this.pages = const {},
    this.details = const {},
    this.throwOnRoot = false,
  });

  final Map<int, Map<String, dynamic>> pages;
  final Map<String, Map<String, dynamic>> details;
  final bool throwOnRoot;
  final List<int> requestedCursors = [];

  @override
  Future<http.Response> getRecommendationHistoryBatches(
    String userId, {
    int cursor = 0,
    int pageSize = 12,
  }) async {
    requestedCursors.add(cursor);
    if (throwOnRoot) {
      throw const SocketExceptionForTest();
    }
    return http.Response(jsonEncode(pages[cursor] ?? _historyPage([])), 200);
  }

  @override
  Future<http.Response> getRecommendationHistoryBatchDetail(
    String userId,
    String batchId,
  ) async {
    return http.Response(
        jsonEncode(details[batchId] ?? <String, dynamic>{}), 200);
  }
}

class SocketExceptionForTest implements Exception {
  const SocketExceptionForTest();
}

class _MemoryHistoryStore implements RecommendationHistoryStore {
  _MemoryHistoryStore([Map<String, String>? values])
      : values = values ?? <String, String>{};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

Map<String, dynamic> _historyPage(
  List<Map<String, dynamic>> items, {
  int? nextCursor,
  bool hasMore = false,
}) {
  return {
    'items': items,
    'nextCursor': nextCursor ?? items.length,
    'hasMore': hasMore,
    'legacyArchive': null,
  };
}

Map<String, dynamic> _batch(
  String id,
  String generatedAt, {
  int mode = 0,
}) {
  return {
    'batchId': id,
    'generatedAt': generatedAt,
    'movieType': 0,
    'discoveryLevel': mode,
    'ratingsVersion': 'ratings-v1',
    'promptVersion': 'recommendations-v5-evidence-grounded',
    'scoreVersion': 'ranking-v1-bounded-signals',
    'model': 'provider-configured',
    'itemCount': 10,
    'previewItems': [
      _movie('preview-$id-1', 'Preview one'),
      _movie('preview-$id-2', 'Preview two'),
      _movie('preview-$id-3', 'Preview three'),
      _movie('preview-$id-4', 'Preview four'),
    ],
  };
}

Map<String, dynamic> _detail(String id) {
  return {
    'batchId': id,
    'generatedAt': '2026-08-14T18:00:00Z',
    'movieType': 0,
    'discoveryLevel': 2,
    'itemCount': 2,
    'items': [
      {
        'rank': 1,
        'movie': _movie('dune', 'Dune', movieRate: 4),
        'matchLabel': 'Strong match',
        'rankScore': 42.4,
        'explanation':
            'Its Science Fiction overlap connects directly to your like for Arrival.',
        'userAction': 'watchlisted',
      },
      {
        'rank': 2,
        'movie': _movie('arrival', 'Arrival', movieRate: 1),
        'matchLabel': 'Good match',
        'rankScore': 38.2,
        'explanation':
            'Director Denis Villeneuve connects directly to your rated titles.',
        'userAction': 'seen-rated',
      },
    ],
  };
}

Map<String, dynamic> _movie(
  String id,
  String title, {
  int movieRate = 0,
}) {
  return {
    'id': id,
    'title': title,
    'tagline': '',
    'overview': 'A grounded recommendation.',
    'posterPath': '',
    'genres': ['Science Fiction', 'Drama'],
    'releaseDate': '2021-01-01T00:00:00Z',
    'duration': 120,
    'likedVotes': 100,
    'unlikedVotes': 10,
    'movieRate': movieRate,
    'movieType': 0,
    'countries': 'United States of America',
    'actors': <String>[],
    'directors': <String>[],
    'seasonsCount': 0,
    'averageTimeOfEpisode': 0,
    'inProduction': false,
    'imdbRate': 8.2,
    'imdbVotes': 100000,
    'recommendationMatchPercent': 0,
    'recommendationMatchLabel': null,
    'recommendationRankScore': 0,
    'recommendationReason': null,
    'recommendationScoreVersion': null,
    'recommendationPromptVersion': null,
    'recommendationGeneratedAt': null,
    'recommendationDiscoveryLevel': null,
    'updated': '2026-08-14T18:00:00Z',
  };
}
