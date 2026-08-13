import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Helpers/movie_list_curator.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/discover_page.dart';
import 'package:mmobile/Widgets/movies_list_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stable TMDb metadata wins without merging competing Popular lists', () {
    final tmdbByMetadata = _list(
      'Current cinema feed',
      [_movie('metadata-movie', MovieType.movie)],
      sourceKey: 'tmdb:popular:movies',
      order: 9,
    );
    final canonicalNameFallback = _list(
      'Popular Movies (TMDb)',
      [_movie('name-fallback', MovieType.movie)],
      order: 1,
    );
    final movieDiary = _list(
      'Popular Movies (MovieDiary)',
      [_movie('moviediary', MovieType.movie)],
      order: 0,
    );
    final teamChoice = _list(
      'MovieDiary Team Choice (Movies)',
      [_movie('team-choice', MovieType.movie)],
      order: 0,
    );

    final selected = MovieListCurator.listForPurpose(
      [movieDiary, canonicalNameFallback, teamChoice, tmdbByMetadata],
      CuratedMovieListPurpose.popularMovies,
    );
    final movies = MovieListCurator.moviesForPurpose(
      [movieDiary, canonicalNameFallback, teamChoice, tmdbByMetadata],
      CuratedMovieListPurpose.popularMovies,
    );

    expect(identical(selected, tmdbByMetadata), isTrue);
    expect(movies.map((movie) => movie.id), ['metadata-movie']);
  });

  test('canonical names remain a fallback and movie types never cross', () {
    final movieList = _list(
      'Popular Movies (TMDb)',
      [
        _movie('movie', MovieType.movie),
        _movie('wrong-tv', MovieType.tv),
      ],
    );
    final tvList = _list(
      'Popular TV Series (TMDb)',
      [
        _movie('tv', MovieType.tv),
        _movie('wrong-movie', MovieType.movie),
      ],
    );

    expect(
      MovieListCurator.moviesForPurpose(
        [tvList, movieList],
        CuratedMovieListPurpose.popularMovies,
      ).map((movie) => movie.id),
      ['movie'],
    );
    expect(
      MovieListCurator.moviesForPurpose(
        [movieList, tvList],
        CuratedMovieListPurpose.popularTv,
      ).map((movie) => movie.id),
      ['tv'],
    );
  });

  test('freshness metadata suppresses stale TMDb popularity', () {
    final now = DateTime.utc(2026, 8, 9, 20);
    final staleList = _list(
      'Popular Movies (TMDb)',
      [_movie('stale', MovieType.movie)],
      sourceUpdatedAt: now.subtract(const Duration(days: 3)),
    );

    expect(
      MovieListCurator.isStalePopularSource(staleList, now: now),
      isTrue,
    );
    expect(
      MovieListCurator.moviesForPurpose(
        [staleList],
        CuratedMovieListPurpose.popularMovies,
      ),
      isEmpty,
    );
  });

  testWidgets(
    'Show all routes to each exact list and Back restores Discover scroll',
    (tester) async {
      final harness = await _Harness.create(_exactPopularLists());
      addTearDown(harness.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(411, 914));

      await tester.pumpWidget(harness.app());
      await tester.pump();

      final moviesAction = find.byKey(
        const ValueKey('discover-section-action-Popular Movies'),
      );
      await tester.ensureVisible(moviesAction);
      await tester.pump();
      final moviesOffset = harness.scrollController.offset;

      await tester.tap(moviesAction);
      await tester.pumpAndSettle();
      expect(find.byType(MoviesListPage), findsOneWidget);
      expect(find.text('Popular Movies (TMDb)'), findsOneWidget);
      expect(find.text('TMDb movie 1'), findsOneWidget);
      expect(find.text('MovieDiary movie'), findsNothing);
      await tester.tap(find.byTooltip('Back to Discover'));
      await tester.pumpAndSettle();

      expect(find.byType(DiscoverPage), findsOneWidget);
      expect(harness.scrollController.offset, closeTo(moviesOffset, 0.5));

      final tvAction = find.byKey(
        const ValueKey('discover-section-action-Popular TV'),
      );
      await tester.ensureVisible(tvAction);
      await tester.pump();
      final tvOffset = harness.scrollController.offset;

      await tester.tap(tvAction);
      await tester.pumpAndSettle();
      expect(find.text('Popular TV Series (TMDb)'), findsOneWidget);
      expect(find.text('TMDb TV 1'), findsOneWidget);
      expect(find.text('TMDb movie 1'), findsNothing);
      await tester.tap(find.byTooltip('Back to Discover'));
      await tester.pumpAndSettle();

      expect(harness.scrollController.offset, closeTo(tvOffset, 0.5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing TMDb source stays truthful and offers a compact retry',
    (tester) async {
      final harness = await _Harness.create([
        _list(
          'Popular Movies (MovieDiary)',
          [_movie('moviediary', MovieType.movie, title: 'MovieDiary movie')],
        ),
      ]);
      addTearDown(harness.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(harness.app());
      await tester.pump();

      final state = find.byKey(
        const ValueKey('discover-popular-source-state-movies'),
      );
      await tester.ensureVisible(state);
      await tester.pump();

      expect(find.text('TMDb movies unavailable'), findsOneWidget);
      expect(find.text('MovieDiary movie'), findsNothing);
      expect(
        find.byKey(const ValueKey('discover-section-action-Popular Movies')),
        findsNothing,
      );
      expect(find.text('Open General Lists'), findsNothing);
      expect(
        find.text('Popular with MovieDiary members · released titles'),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('discover-popular-retry-movies')),
      );
      await tester.pump();
      expect(harness.retryCount, 1);
      expect(tester.getSize(state).height, lessThan(220));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stale TMDb source is labeled instead of rendered as current',
      (tester) async {
    final harness = await _Harness.create([
      _list(
        'Popular Movies (TMDb)',
        [_movie('stale', MovieType.movie)],
        sourceUpdatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      _list(
        'Popular TV Series (TMDb)',
        [_movie('tv', MovieType.tv)],
      ),
    ]);
    addTearDown(harness.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 930));

    await tester.pumpWidget(harness.app(textScale: 1.3));
    await tester.pump();
    final state = find.byKey(
      const ValueKey('discover-popular-source-state-movies'),
    );
    await tester.ensureVisible(state);
    await tester.pump();

    expect(find.text('TMDb movies need refresh'), findsOneWidget);
    expect(find.text('TMDb movie 1'), findsNothing);
    expect(tester.getSize(state).height, lessThan(260));
    expect(tester.takeException(), isNull);
  });
}

class _Harness {
  _Harness({
    required this.userState,
    required this.moviesState,
  });

  final UserState userState;
  final MoviesState moviesState;
  final scrollController = ScrollController();
  int retryCount = 0;

  static Future<_Harness> create(List<MoviesList> lists) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
    moviesState.setExternalMoviesLists(lists);
    moviesState.markMoviesListsRequestFinished();
    return _Harness(userState: userState, moviesState: moviesState);
  }

  Widget app({double textScale = 1}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserState>.value(value: userState),
        ChangeNotifierProvider<MoviesState>.value(value: moviesState),
      ],
      child: MaterialApp(
        theme: MovieDiaryTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: Md3Colors.background,
          body: DiscoverPage(
            scrollController: scrollController,
            onRetry: () async => retryCount += 1,
          ),
        ),
      ),
    );
  }

  void dispose() {
    scrollController.dispose();
    moviesState.dispose();
    userState.dispose();
  }
}

List<MoviesList> _exactPopularLists() {
  return [
    _list(
      'Popular Movies (MovieDiary)',
      [_movie('md-movie', MovieType.movie, title: 'MovieDiary movie')],
      order: 0,
    ),
    _list(
      'Popular Movies (TMDb)',
      [
        _movie('tmdb-movie-1', MovieType.movie, title: 'TMDb movie 1'),
        _movie('tmdb-movie-2', MovieType.movie, title: 'TMDb movie 2'),
        _movie('wrong-tv', MovieType.tv, title: 'Wrong TV'),
      ],
      order: 4,
    ),
    _list(
      'Popular TV Series (TMDb)',
      [
        _movie('tmdb-tv-1', MovieType.tv, title: 'TMDb TV 1'),
        _movie('wrong-movie', MovieType.movie, title: 'Wrong movie'),
      ],
      order: 5,
    ),
  ];
}

MoviesList _list(
  String name,
  List<Movie> movies, {
  int order = 1,
  String? sourceKey,
  DateTime? sourceUpdatedAt,
}) {
  return MoviesList(
    name: name,
    order: order,
    listMovies: movies,
    movieListType: MovieListType.external,
    sourceKey: sourceKey,
    sourceUpdatedAt: sourceUpdatedAt,
  );
}

Movie _movie(
  String id,
  MovieType type, {
  String? title,
}) {
  return Movie(
    id: id,
    title: title ?? (type == MovieType.movie ? 'TMDb movie 1' : 'TMDb TV 1'),
    overview: 'Overview',
    tagline: null,
    posterPath: 'poster.jpg',
    duration: type == MovieType.movie ? 110 : 48,
    rating: 80,
    allVotes: 20,
    likedVotes: 16,
    dislikedVotes: 4,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Drama'],
    movieRate: MovieRate.notRated,
    movieType: type,
    releaseDate: DateTime(2024),
    averageTimeOfEpisode: type == MovieType.tv ? 48 : 0,
    inProduction: false,
    seasonsCount: type == MovieType.tv ? 2 : 0,
    imdbRate: 8,
    imdbVotes: 10000,
  );
}
