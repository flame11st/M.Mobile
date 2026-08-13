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
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/discover_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Discover caps all three previews at five real titles',
      (tester) async {
    final harness = await _Harness.create(
      popularMovieCount: 8,
      popularTvCount: 8,
      watchlistCount: 8,
    );
    addTearDown(harness.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(411, 914));

    await tester.pumpWidget(harness.app());
    await tester.pump();

    for (var index = 1; index <= 5; index += 1) {
      expect(find.text('Popular movie $index'), findsOneWidget);
      expect(find.text('Popular TV $index'), findsOneWidget);
      expect(find.text('Watchlist title $index'), findsOneWidget);
    }
    for (var index = 6; index <= 8; index += 1) {
      expect(find.text('Popular movie $index'), findsNothing);
      expect(find.text('Popular TV $index'), findsNothing);
      expect(find.text('Watchlist title $index'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('short previews render every available title exactly once',
      (tester) async {
    final harness = await _Harness.create(
      popularMovieCount: 4,
      popularTvCount: 2,
      watchlistCount: 3,
    );
    addTearDown(harness.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(harness.app());
    await tester.pump();

    for (var index = 1; index <= 4; index += 1) {
      expect(find.text('Popular movie $index'), findsOneWidget);
    }
    for (var index = 1; index <= 2; index += 1) {
      expect(find.text('Popular TV $index'), findsOneWidget);
    }
    for (var index = 1; index <= 3; index += 1) {
      expect(find.text('Watchlist title $index'), findsOneWidget);
    }
    expect(find.textContaining('placeholder'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Watchlist View All stays aligned, accessible, and routes when empty',
    (tester) async {
      final harness = await _Harness.create(
        popularMovieCount: 1,
        popularTvCount: 1,
        watchlistCount: 0,
      );
      addTearDown(harness.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(430, 930));

      await tester.pumpWidget(harness.app(textScale: 1.3));
      await tester.pump();

      final title = find.byKey(
        const ValueKey('discover-section-title-Your Watchlist'),
      );
      final action = find.byKey(
        const ValueKey('discover-section-action-Your Watchlist'),
      );
      await tester.ensureVisible(action);
      await tester.pump();

      expect(find.text('Your watchlist is ready'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
      expect(
        (tester.getCenter(title).dy - tester.getCenter(action).dy).abs(),
        lessThan(8),
      );
      expect(
        tester.getSemantics(action).label,
        contains('View all Your Watchlist movies'),
      );

      await tester.tap(action);
      await tester.pump();
      expect(harness.openWatchlistCount, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Harness {
  _Harness({
    required this.userState,
    required this.moviesState,
  });

  final UserState userState;
  final MoviesState moviesState;
  int openWatchlistCount = 0;

  static Future<_Harness> create({
    required int popularMovieCount,
    required int popularTvCount,
    required int watchlistCount,
  }) async {
    FlutterSecureStorage.setMockInitialValues({
      'userId': 'uxr34-guest',
      'isIncognitoMode': 'true',
    });
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
    moviesState.setInitialUserMovies(
      List.generate(
        watchlistCount,
        (index) => _movie(
          'watchlist-${index + 1}',
          'Watchlist title ${index + 1}',
          MovieType.movie,
          movieRate: MovieRate.addedToWatchlist,
        ),
      ),
    );
    moviesState.setExternalMoviesLists([
      MoviesList(
        name: 'Popular Movies (TMDb)',
        order: 1,
        movieListType: MovieListType.external,
        listMovies: List.generate(
          popularMovieCount,
          (index) => _movie(
            'popular-movie-${index + 1}',
            'Popular movie ${index + 1}',
            MovieType.movie,
          ),
        ),
      ),
      MoviesList(
        name: 'Popular TV Series (TMDb)',
        order: 2,
        movieListType: MovieListType.external,
        listMovies: List.generate(
          popularTvCount,
          (index) => _movie(
            'popular-tv-${index + 1}',
            'Popular TV ${index + 1}',
            MovieType.tv,
          ),
        ),
      ),
    ]);
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
        home: Material(
          color: Md3Colors.background,
          child: DiscoverPage(
            onOpenWatchlist: () => openWatchlistCount += 1,
          ),
        ),
      ),
    );
  }

  void dispose() {
    moviesState.dispose();
    userState.dispose();
  }
}

Movie _movie(
  String id,
  String title,
  MovieType type, {
  int movieRate = MovieRate.notRated,
}) {
  return Movie(
    id: id,
    title: title,
    overview: 'A useful synopsis.',
    tagline: null,
    posterPath: '',
    duration: 110,
    rating: 80,
    allVotes: 100,
    likedVotes: 80,
    dislikedVotes: 20,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Drama'],
    movieRate: movieRate,
    movieType: type,
    releaseDate: DateTime(2025),
    averageTimeOfEpisode: type == MovieType.tv ? 48 : 0,
    inProduction: false,
    seasonsCount: type == MovieType.tv ? 2 : 0,
    imdbRate: 8,
    imdbVotes: 1000,
  );
}
