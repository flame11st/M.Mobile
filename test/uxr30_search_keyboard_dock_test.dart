import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/search_page.dart';
import 'package:mmobile/Widgets/search_state.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('landing starts 16 points below the pinned field',
      (tester) async {
    await _pumpSearch(
      tester,
      fetcher: (_, __) async => const MovieSearchTransportResponse(
        statusCode: 200,
        body: '[]',
      ),
    );

    expect(
        _listTopPadding(tester, find.byKey(const Key('search-landing'))), 16);
  });

  testWidgets('loading starts 16 points below the pinned field',
      (tester) async {
    final response = Completer<MovieSearchTransportResponse>();
    await _pumpSearch(tester, fetcher: (_, __) => response.future);

    await tester.enterText(find.byType(TextField), 'Matrix');
    await tester.pump(const Duration(milliseconds: 451));

    final loading = _listWithKeyPrefix('search-loading-');
    expect(loading, findsOneWidget);
    expect(_listTopPadding(tester, loading), 16);

    response.complete(
      const MovieSearchTransportResponse(statusCode: 200, body: '[]'),
    );
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pumpAndSettle();
  });

  testWidgets('results start 16 points below the pinned field', (tester) async {
    await _pumpSearch(
      tester,
      fetcher: (_, __) async => _movieResponse('The Matrix'),
    );

    await tester.enterText(find.byType(TextField), 'Matrix');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pumpAndSettle();

    final results = _listWithKeyPrefix('search-results-');
    expect(results, findsOneWidget);
    expect(_listTopPadding(tester, results), 16);
  });

  testWidgets('empty and error recovery states keep the same 16 point edge',
      (tester) async {
    var fail = false;
    await _pumpSearch(
      tester,
      fetcher: (_, __) async => MovieSearchTransportResponse(
        statusCode: fail ? 500 : 200,
        body: '[]',
      ),
    );

    await tester.enterText(find.byType(TextField), 'No such title');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pumpAndSettle();
    expect(
      _listTopPadding(tester, _listWithKeyPrefix('search-empty-')),
      16,
    );

    fail = true;
    await tester.enterText(find.byType(TextField), 'Offline title');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pumpAndSettle();
    expect(
      _listTopPadding(tester, find.byKey(const Key('search-error'))),
      16,
    );
  });

  testWidgets('timeout keeps the same 16 point edge', (tester) async {
    final response = Completer<MovieSearchTransportResponse>();
    await _pumpSearch(tester, fetcher: (_, __) => response.future);

    await tester.enterText(find.byType(TextField), 'Slow title');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();

    expect(
      _listTopPadding(tester, find.byKey(const Key('search-timeout'))),
      16,
    );
  });
}

Future<void> _pumpSearch(
  WidgetTester tester, {
  required MovieSearchFetcher fetcher,
}) async {
  final moviesState = MoviesState();
  addTearDown(moviesState.dispose);
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ChangeNotifierProvider<MoviesState>.value(
      value: moviesState,
      child: MaterialApp(
        home: Scaffold(
          body: SearchPage(
            handlesBackNavigation: false,
            showBottomNavigationClearance: false,
            fetcher: fetcher,
            suggestionStore: _MemorySuggestionStore(),
            suggestionFetcher: () async => const MovieSearchTransportResponse(
              statusCode: 200,
              body: '[]',
            ),
            automaticSuggestionRetryDelays: const [],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _listWithKeyPrefix(String prefix) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is ListView &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith(prefix),
  );
}

double _listTopPadding(WidgetTester tester, Finder finder) {
  final list = tester.widget<ListView>(finder);
  return (list.padding! as EdgeInsets).top;
}

MovieSearchTransportResponse _movieResponse(String title) {
  return MovieSearchTransportResponse(
    statusCode: 200,
    body: jsonEncode([
      {
        'id': '603',
        'title': title,
        'tagline': null,
        'overview': 'Overview',
        'posterPath': '',
        'genres': ['Action', 'Science Fiction'],
        'releaseDate': '1999-03-31T00:00:00.000Z',
        'duration': 136,
        'likedVotes': 10,
        'unlikedVotes': 2,
        'movieRate': 0,
        'movieType': 0,
        'countries': 'United States',
        'actors': <String>[],
        'directors': <String>[],
        'seasonsCount': 0,
        'averageTimeOfEpisode': 0,
        'inProduction': false,
        'imdbRate': 8.7,
        'imdbVotes': 2000000,
      }
    ]),
  );
}

class _MemorySuggestionStore implements SearchSuggestionStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
