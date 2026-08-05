import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Widgets/search_page.dart';
import 'package:mmobile/Widgets/search_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Search popular suggestions', () {
    testWidgets('error exposes Retry and retry recovers real popular chips',
        (tester) async {
      var attempts = 0;
      final store = _MemorySuggestionStore();

      await _pumpSearch(
        tester,
        store: store,
        suggestionFetcher: () async {
          attempts += 1;
          if (attempts == 1) {
            return const MovieSearchTransportResponse(
              statusCode: 500,
              body: '',
            );
          }
          return _popularResponse(['The Matrix', 'Iron Man', 'Toy Story']);
        },
      );

      expect(find.text('Popular searches unavailable'), findsOneWidget);
      expect(
          find.text('Check your connection, then try again.'), findsOneWidget);
      expect(find.text('Retry suggestions'), findsOneWidget);

      await tester.tap(find.text('Retry suggestions'));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('Popular searches'), findsOneWidget);
      expect(find.text('The Matrix'), findsOneWidget);
      expect(find.text('Iron Man'), findsOneWidget);
      expect(find.text('Toy Story'), findsOneWidget);
      expect(find.text('Popular searches unavailable'), findsNothing);
    });

    testWidgets('failed tab revisit retries once without a success loop',
        (tester) async {
      var attempts = 0;
      var isActive = true;
      late StateSetter setHostState;
      final store = _MemorySuggestionStore();

      await tester.pumpWidget(
        _testApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return SearchPage(
                key: const ValueKey('persistent-search'),
                isActive: isActive,
                handlesBackNavigation: false,
                showBottomNavigationClearance: false,
                suggestionStore: store,
                suggestionRefreshThrottle: const Duration(minutes: 5),
                automaticSuggestionRetryDelays: const [],
                suggestionFetcher: () async {
                  attempts += 1;
                  if (attempts == 1) {
                    return const MovieSearchTransportResponse(
                      statusCode: 401,
                      body: '',
                    );
                  }
                  return _popularResponse(['Arrival']);
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(attempts, 1);
      expect(find.text('Popular searches unavailable'), findsOneWidget);

      setHostState(() => isActive = false);
      await tester.pump();
      setHostState(() => isActive = true);
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('Arrival'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(attempts, 2);
    });

    testWidgets('tab exit ignores the stale search and resumes the exact query',
        (tester) async {
      var isActive = true;
      late StateSetter setHostState;
      final firstResponse = Completer<MovieSearchTransportResponse>();
      final resumedResponse = Completer<MovieSearchTransportResponse>();
      final searchedQueries = <String>[];

      await tester.pumpWidget(
        _testApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return SearchPage(
                key: const ValueKey('persistent-search'),
                isActive: isActive,
                handlesBackNavigation: false,
                showBottomNavigationClearance: false,
                suggestionStore: _MemorySuggestionStore(),
                suggestionFetcher: () async =>
                    const MovieSearchTransportResponse(
                  statusCode: 200,
                  body: '[]',
                ),
                automaticSuggestionRetryDelays: const [],
                fetcher: (encodedQuery, _) {
                  searchedQueries.add(Uri.decodeQueryComponent(encodedQuery));
                  return searchedQueries.length == 1
                      ? firstResponse.future
                      : resumedResponse.future;
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Matrix  ');
      await tester.pump(const Duration(milliseconds: 500));
      expect(searchedQueries, ['Matrix']);

      setHostState(() => isActive = false);
      await tester.pump();
      firstResponse.complete(
        const MovieSearchTransportResponse(statusCode: 500, body: ''),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Search unavailable'), findsNothing);

      setHostState(() => isActive = true);
      await tester.pump();
      expect(searchedQueries, ['Matrix', 'Matrix']);

      resumedResponse.complete(
        const MovieSearchTransportResponse(statusCode: 200, body: '[]'),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('No titles found'), findsOneWidget);
      expect(find.text('Search unavailable'), findsNothing);
    });

    testWidgets('cached chips stay visible through refresh and failure',
        (tester) async {
      final response = Completer<MovieSearchTransportResponse>();
      final now = DateTime.utc(2026, 7, 29, 12);
      final store = _MemorySuggestionStore({
        'movieDiaryPopularSearches': jsonEncode(['The Matrix']),
        'movieDiaryPopularSearchesUpdatedAt':
            now.subtract(const Duration(minutes: 10)).toIso8601String(),
      });

      await tester.pumpWidget(
        _testApp(
          child: SearchPage(
            handlesBackNavigation: false,
            showBottomNavigationClearance: false,
            suggestionStore: store,
            suggestionFetcher: () => response.future,
            suggestionTimeout: const Duration(seconds: 1),
            suggestionRefreshThrottle: const Duration(minutes: 5),
            automaticSuggestionRetryDelays: const [],
            clock: () => now,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('The Matrix'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Popular searches unavailable'), findsNothing);

      response.complete(
        const MovieSearchTransportResponse(statusCode: 500, body: ''),
      );
      await tester.pumpAndSettle();

      expect(find.text('The Matrix'), findsOneWidget);
      expect(
        find.text(
          'Showing saved suggestions. Refresh when you’re back online.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('empty popular data stays distinct and Recent can coexist',
        (tester) async {
      final store = _MemorySuggestionStore({
        'movieDiaryRecentSuccessfulSearches': jsonEncode(['Arrival']),
      });

      await _pumpSearch(
        tester,
        store: store,
        suggestionFetcher: () async => const MovieSearchTransportResponse(
          statusCode: 200,
          body: '[]',
        ),
      );

      expect(
        find.text('Popular searches are still building'),
        findsOneWidget,
      );
      expect(
        find.text(
          'They’ll appear after more successful MovieDiary searches.',
        ),
        findsOneWidget,
      );
      expect(find.text('Recent searches'), findsOneWidget);
      expect(find.text('Arrival'), findsOneWidget);
    });

    testWidgets('timeout maps to the explicit suggestion error state',
        (tester) async {
      final pending = Completer<MovieSearchTransportResponse>();

      await tester.pumpWidget(
        _testApp(
          child: SearchPage(
            handlesBackNavigation: false,
            showBottomNavigationClearance: false,
            suggestionStore: _MemorySuggestionStore(),
            suggestionFetcher: () => pending.future,
            suggestionTimeout: const Duration(milliseconds: 10),
            automaticSuggestionRetryDelays: const [],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 11));
      await tester.pump();

      expect(find.text('Popular searches unavailable'), findsOneWidget);
      expect(find.text('Retry suggestions'), findsOneWidget);
    });

    testWidgets('automatic backoff recovers while Search remains active',
        (tester) async {
      var attempts = 0;

      await _pumpSearch(
        tester,
        store: _MemorySuggestionStore(),
        automaticRetryDelays: const [Duration(milliseconds: 10)],
        suggestionFetcher: () async {
          attempts += 1;
          if (attempts == 1) {
            return const MovieSearchTransportResponse(
              statusCode: 500,
              body: '',
            );
          }
          return _popularResponse(['Toy Story']);
        },
      );

      await tester.pump(const Duration(milliseconds: 11));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('Toy Story'), findsOneWidget);
    });

    testWidgets('suggestion failure never blocks normal title search',
        (tester) async {
      await _pumpSearch(
        tester,
        store: _MemorySuggestionStore(),
        suggestionFetcher: () async => const MovieSearchTransportResponse(
          statusCode: 500,
          body: '',
        ),
        searchFetcher: (_, __) async => const MovieSearchTransportResponse(
          statusCode: 200,
          body: '[]',
        ),
      );

      expect(find.text('Popular searches unavailable'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'A title that is not indexed',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('No titles found'), findsOneWidget);
      expect(find.text('Popular searches unavailable'), findsNothing);
    });

    for (final variant in [
      (size: const Size(360, 640), textScale: 1.0),
      (size: const Size(360, 640), textScale: 1.3),
      (size: const Size(360, 640), textScale: 2.0),
      (size: const Size(430, 930), textScale: 2.0),
    ]) {
      testWidgets(
          'both sections fit ${variant.size.width.toInt()}x'
          '${variant.size.height.toInt()} at ${variant.textScale}x text',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = variant.size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await _pumpSearch(
          tester,
          textScale: variant.textScale,
          store: _MemorySuggestionStore({
            'movieDiaryRecentSuccessfulSearches':
                jsonEncode(['Arrival', 'Dune']),
          }),
          suggestionFetcher: () async => _popularResponse([
            'The Matrix',
            'The Assassination of Jesse James by the Coward Robert Ford',
            'Toy Story',
          ]),
        );

        expect(find.text('Popular searches'), findsOneWidget);
        for (var scrollAttempt = 0;
            scrollAttempt < 4 &&
                find.text('Recent searches').evaluate().isEmpty;
            scrollAttempt += 1) {
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -300),
          );
          await tester.pump();
        }
        expect(find.text('Recent searches'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

Future<void> _pumpSearch(
  WidgetTester tester, {
  required SearchSuggestionStore store,
  required PopularSearchFetcher suggestionFetcher,
  MovieSearchFetcher? searchFetcher,
  List<Duration> automaticRetryDelays = const [],
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    _testApp(
      textScale: textScale,
      child: SearchPage(
        handlesBackNavigation: false,
        showBottomNavigationClearance: false,
        suggestionStore: store,
        suggestionFetcher: suggestionFetcher,
        fetcher: searchFetcher,
        suggestionTimeout: const Duration(milliseconds: 100),
        suggestionRefreshThrottle: Duration.zero,
        automaticSuggestionRetryDelays: automaticRetryDelays,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _testApp({
  required Widget child,
  double textScale = 1,
}) {
  return MaterialApp(
    builder: (context, appChild) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: appChild!,
      );
    },
    home: Scaffold(body: child),
  );
}

MovieSearchTransportResponse _popularResponse(List<String> suggestions) {
  return MovieSearchTransportResponse(
    statusCode: 200,
    body: jsonEncode([
      for (final suggestion in suggestions) {'query': suggestion},
    ]),
  );
}

class _MemorySuggestionStore implements SearchSuggestionStore {
  final Map<String, String> values;

  _MemorySuggestionStore([Map<String, String>? values]) : values = {...?values};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
