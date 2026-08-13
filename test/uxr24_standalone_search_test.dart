import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/movies_list_page.dart';
import 'package:mmobile/Widgets/search_page.dart';
import 'package:mmobile/Widgets/search_state.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'standalone Search exposes a 48px list-aware Back control and native pop',
    (tester) async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      await _configureMediumPhone(tester);

      await tester.pumpWidget(harness.app());
      await harness.openSearch(tester);

      final back = find.byKey(const ValueKey('standalone-search-back'));
      expect(back, findsOneWidget);
      expect(find.byTooltip('Back to Favorites'), findsOneWidget);
      expect(tester.getSize(back), const Size(48, 48));
      expect(
        find.text('Add movies and TV shows to “Favorites”.'),
        findsOneWidget,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Search'), findsOneWidget);
      expect(
          tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
          isFalse);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Origin list route'), findsOneWidget);
      expect(find.text('Search'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Android IME focus loss is consumed before the nested route pop',
    (tester) async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      await _configureMediumPhone(tester);

      await tester.pumpWidget(harness.app());
      await harness.openSearch(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Search'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Origin list route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'originating list is the direct Add target and updates before return',
    (tester) async {
      final harness = await _Harness.create(
        additionalLists: [
          MoviesList(
            name: 'Weekend Picks',
            order: 2,
            listMovies: [],
            movieListType: MovieListType.personal,
          ),
        ],
      );
      addTearDown(harness.dispose);
      await _configureMediumPhone(tester);

      await tester.pumpWidget(harness.app(textScale: 1.3));
      await harness.openSearch(tester);
      await _showMatrixResults(tester);

      await tester.tap(find.byTooltip('Movie actions'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add to Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('Add to Favorites'), findsOneWidget);
      expect(find.text('Your open personal list.'), findsOneWidget);
      expect(find.text('Choose another personal list'), findsOneWidget);

      await tester.tap(find.text('Add to Favorites'));
      await tester.pumpAndSettle();

      expect(
        harness.originatingList.listMovies.map((movie) => movie.id),
        contains('matrix'),
      );
      expect(find.text('Added to Favorites.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('standalone-search-back')));
      await tester.pumpAndSettle();
      expect(find.text('Origin list route'), findsOneWidget);
      expect(harness.originatingList.listMovies, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removed originating list shows a clear fallback instead of crashing',
    (tester) async {
      final fallbackList = MoviesList(
        name: 'Weekend Picks',
        order: 2,
        listMovies: [],
        movieListType: MovieListType.personal,
      );
      final harness = await _Harness.create(additionalLists: [fallbackList]);
      addTearDown(harness.dispose);
      await _configureMediumPhone(tester);

      await tester.pumpWidget(harness.app());
      await harness.openSearch(tester);
      await _showMatrixResults(tester);

      harness.movies.removeMoviesList('Favorites');
      await tester.pump();
      await tester.tap(find.byTooltip('Movie actions'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text(
          '“Favorites” changed or is no longer available. '
          'Choose another list.',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          '“Favorites” changed or is no longer available. '
          'Choose another list.',
        ),
        findsOneWidget,
      );
      expect(find.text('Weekend Picks'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renamed originating list stays the preferred target',
      (tester) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await _configureMediumPhone(tester);

    await tester.pumpWidget(harness.app());
    await harness.openSearch(tester);
    await _showMatrixResults(tester);

    await harness.movies.renameMoviesList('Favorites', 'Fresh Favorites');
    await tester.pump();
    await tester.tap(find.byTooltip('Movie actions'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add to Fresh Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Fresh Favorites'), findsOneWidget);
    expect(find.text('Your open personal list.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets(
      'empty list refreshes immediately after standalone Search returns',
      (tester) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await _configureMediumPhone(tester);

    await tester.pumpWidget(
      harness.app(
        home: MoviesListPage(moviesList: harness.originatingList),
      ),
    );
    expect(find.text('This list is empty'), findsOneWidget);

    await tester.tap(find.text('Search Movies or TV Shows'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byTooltip('Back to Favorites'), findsOneWidget);

    harness.movies.addMovieToPersonalList('Favorites', _matrixMovie());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('standalone-search-back')));
    await tester.pumpAndSettle();

    expect(find.text('This list is empty'), findsNothing);
    expect(find.text('The Matrix'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 800));
  });
}

Future<void> _configureMediumPhone(
  WidgetTester tester,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _showMatrixResults(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Matrix');
  await tester.pump(const Duration(milliseconds: 451));
  await tester.pump(const Duration(milliseconds: 601));
  await tester.pumpAndSettle();
  expect(find.text('The Matrix'), findsOneWidget);
}

class _Harness {
  final UserState user;
  final MoviesState movies;
  final MoviesList originatingList;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  _Harness({
    required this.user,
    required this.movies,
    required this.originatingList,
  });

  static Future<_Harness> create({
    List<MoviesList> additionalLists = const [],
  }) async {
    FlutterSecureStorage.setMockInitialValues({
      'token': 'guest-access',
      'refreshToken': 'guest-refresh',
      'userId': 'uxr24-guest',
      'isIncognitoMode': 'true',
    });
    const storage = FlutterSecureStorage();
    final user = UserState(storage: storage);
    await user.initialization;
    final movies = MoviesState(storage: storage);
    await movies.cacheInitialization;
    final originatingList = MoviesList(
      name: 'Favorites',
      order: 1,
      listMovies: [],
      movieListType: MovieListType.personal,
    );
    await movies.setInitialMoviesLists([
      originatingList,
      ...additionalLists,
    ]);
    return _Harness(
      user: user,
      movies: movies,
      originatingList: originatingList,
    );
  }

  Widget app({
    double textScale = 1,
    Widget? home,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserState>.value(value: user),
        ChangeNotifierProvider<MoviesState>.value(value: movies),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          );
        },
        home: home ??
            const Scaffold(
              body: Center(child: Text('Origin list route')),
            ),
      ),
    );
  }

  Future<void> openSearch(WidgetTester tester) async {
    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SearchStandalonePage(
            originatingPersonalList: originatingList,
            suggestionStore: _MemorySuggestionStore(),
            suggestionFetcher: () async => const MovieSearchTransportResponse(
              statusCode: 200,
              body: '[]',
            ),
            automaticSuggestionRetryDelays: const [],
            fetcher: (_, __) async => MovieSearchTransportResponse(
              statusCode: 200,
              body: jsonEncode([_matrixMovie().toJson()]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void dispose() {
    movies.dispose();
    user.dispose();
  }
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

Movie _matrixMovie() {
  return Movie(
    id: 'matrix',
    title: 'The Matrix',
    overview: 'A hacker discovers the truth about his world.',
    tagline: 'Free your mind.',
    posterPath: '',
    duration: 136,
    rating: 88,
    allVotes: 100,
    likedVotes: 88,
    dislikedVotes: 12,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Science Fiction', 'Action'],
    movieRate: MovieRate.notRated,
    movieType: MovieType.movie,
    releaseDate: DateTime(1999),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8.7,
    imdbVotes: 2000000,
  );
}
