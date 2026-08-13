import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/movie_list.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'external Watchlist selection overrides the previously viewed tab',
    (tester) async {
      final states = await _testStates([
        _movie('saved', 'Saved film', MovieRate.addedToWatchlist),
        _movie('viewed', 'Viewed film', MovieRate.liked),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final libraryKey = GlobalKey<MovieListState>();

      await tester.binding.setSurfaceSize(const Size(411, 914));
      await _pumpLibrary(
        tester,
        states,
        size: const Size(411, 914),
        textScale: 1,
        movieListKey: libraryKey,
      );

      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(find.text('Viewed film'), findsOneWidget);

      libraryKey.currentState!.showWatchlist();
      await tester.pumpAndSettle();

      expect(find.text('Saved film'), findsOneWidget);
      expect(find.text('Viewed film'), findsNothing);
      expect(states.movies.currentTabIndex, 0);

      libraryKey.currentState!.showWatchlist();
      await tester.pumpAndSettle();
      expect(find.text('Saved film'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty library stays compact and exposes one truthful action per tab',
    (tester) async {
      final states = await _testStates(const []);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var discoverTaps = 0;
      var ratingTaps = 0;

      const configurations = [
        (Size(320, 568), 1.0),
        (Size(360, 640), 1.3),
        (Size(390, 844), 2.0),
      ];

      for (final configuration in configurations) {
        await tester.binding.setSurfaceSize(configuration.$1);
        await _pumpLibrary(
          tester,
          states,
          size: configuration.$1,
          textScale: configuration.$2,
          onOpenDiscover: () => discoverTaps += 1,
          onStartRating: () => ratingTaps += 1,
        );

        await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
        await tester.pumpAndSettle();
        expect(find.text('Your Watchlist is empty'), findsOneWidget);
        expect(
          find.text('Save movies and shows you want to watch.'),
          findsOneWidget,
        );
        expect(find.text('Explore Discover'), findsOneWidget);
        expect(find.text('Taste profile'), findsNothing);
        expect(find.text('Start Discovery'), findsNothing);

        final watchlistTarget = tester.getSize(
          find.byKey(const Key('my-movies-tab-watchlist')),
        );
        expect(watchlistTarget.height, greaterThanOrEqualTo(48));

        await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
        await tester.pumpAndSettle();
        expect(find.text('Nothing in Viewed yet'), findsOneWidget);
        expect(
          find.text(
            'Rate something you’ve seen to start your taste profile.',
          ),
          findsOneWidget,
        );
        expect(find.text('Rate Movies'), findsOneWidget);
        expect(find.text('All 0'), findsOneWidget);
        expect(find.text('Liked 0'), findsOneWidget);
        expect(find.text('Okay 0'), findsOneWidget);
        expect(find.text('Disliked 0'), findsOneWidget);

        final allFilterTarget = tester.getSize(
          find.byKey(const Key('viewed-filter-all')),
        );
        expect(allFilterTarget.height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull);
      }

      await tester.ensureVisible(find.text('Rate Movies'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rate Movies'));
      await tester.pump();
      expect(ratingTaps, 1);

      await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Explore Discover'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore Discover'));
      await tester.pump();
      expect(discoverTaps, 1);
    },
  );

  testWidgets(
    'visible opinion filters update immediately and persist across tabs',
    (tester) async {
      final states = await _testStates([
        _movie('liked', 'Liked film', MovieRate.liked),
        _movie('okay', 'Okay film', MovieRate.okay),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await _pumpLibrary(
        tester,
        states,
        size: const Size(360, 640),
        textScale: 1,
      );

      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('Liked 1'), findsOneWidget);
      expect(find.text('Okay 1'), findsOneWidget);
      expect(find.text('Disliked 0'), findsOneWidget);

      await _tapViewedFilter(tester, const Key('viewed-filter-okay'));
      expect(find.text('Okay film'), findsOneWidget);
      expect(find.text('Liked film'), findsNothing);

      await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(find.text('Okay film'), findsOneWidget);
      expect(find.text('Liked film'), findsNothing);

      await _tapViewedFilter(tester, const Key('viewed-filter-disliked'));
      expect(find.text('No Disliked ratings yet'), findsOneWidget);
      expect(find.text('Show all'), findsOneWidget);

      await tester.tap(find.byKey(const Key('viewed-filter-show-all')));
      await tester.pumpAndSettle();
      expect(find.text('Liked film'), findsOneWidget);
      expect(find.text('Okay film'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'advanced Viewed filters combine media, genres, and opinion without touching Watchlist',
    (tester) async {
      final states = await _testStates([
        _movie(
          'liked-movie',
          'Liked movie',
          MovieRate.liked,
          genres: const [' Drama ', 'SCI-FI', ''],
        ),
        _movie(
          'liked-tv',
          'Liked TV',
          MovieRate.liked,
          movieType: MovieType.tv,
          genres: const ['Drama'],
        ),
        _movie(
          'okay-movie',
          'Okay movie',
          MovieRate.okay,
          genres: const ['SCI-FI'],
        ),
        _movie(
          'okay-tv',
          'Okay TV',
          MovieRate.okay,
          movieType: MovieType.tv,
          genres: const ['Drama'],
        ),
        _movie(
          'disliked-tv',
          'Disliked TV',
          MovieRate.notLiked,
          movieType: MovieType.tv,
          genres: const ['Horror'],
        ),
        _movie(
          'saved-comedy',
          'Saved comedy',
          MovieRate.addedToWatchlist,
          genres: const ['Comedy'],
        ),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await _pumpLibrary(
        tester,
        states,
        size: const Size(430, 932),
        textScale: 1,
      );

      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('viewed-advanced-filters')));
      await tester.pumpAndSettle();

      expect(find.text('Advanced filters'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('viewed-genre-drama')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('viewed-genre-sci-fi')),
        findsOneWidget,
      );
      expect(find.text('Comedy'), findsNothing);

      await tester.tap(find.byKey(const Key('viewed-media-movies')));
      await tester.tap(
        find.byKey(const Key('viewed-advanced-filter-close')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Liked TV'), findsOneWidget);
      expect(find.text('Disliked TV'), findsOneWidget);
      expect(states.movies.hasViewedAdvancedFilters, isFalse);

      await tester.tap(find.byKey(const Key('viewed-advanced-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('viewed-media-movies')));
      await tester.tap(
        find.byKey(const Key('viewed-advanced-filter-apply')),
      );
      await tester.pumpAndSettle();

      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('Liked movie'), findsOneWidget);
      expect(find.text('Okay movie'), findsOneWidget);
      expect(find.text('Liked TV'), findsNothing);
      expect(
        find.byKey(const Key('viewed-advanced-filter-count')),
        findsOneWidget,
      );
      final filterSemantics = tester.getSemantics(
        find.byKey(const Key('viewed-advanced-filters')),
      );
      expect(filterSemantics.label, contains('1 active'));
      expect(filterSemantics.flagsCollection.isButton, isTrue);
      expect(filterSemantics.flagsCollection.isSelected, Tristate.isTrue);

      await _tapViewedFilter(tester, const Key('viewed-filter-liked'));
      await tester.tap(find.byKey(const Key('viewed-advanced-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('viewed-media-tv')));
      await tester.tap(
        find.byKey(const Key('viewed-advanced-filter-apply')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Liked TV'), findsOneWidget);
      expect(find.text('Liked movie'), findsNothing);

      await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
      await tester.pumpAndSettle();
      expect(find.text('Saved comedy'), findsOneWidget);
      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(find.text('Liked TV'), findsOneWidget);

      await tester.tap(find.byKey(const Key('viewed-advanced-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('viewed-media-all')));
      await tester.tap(
        find.byKey(const ValueKey<String>('viewed-genre-drama')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('viewed-genre-sci-fi')),
      );
      await tester.tap(
        find.byKey(const Key('viewed-advanced-filter-apply')),
      );
      await tester.pumpAndSettle();

      await _tapViewedFilter(tester, const Key('viewed-filter-okay'));
      expect(find.text('Okay movie'), findsOneWidget);
      expect(find.text('Okay TV'), findsOneWidget);
      expect(find.text('Liked movie'), findsNothing);

      await _tapViewedFilter(tester, const Key('viewed-filter-disliked'));
      expect(find.text('No Viewed titles match'), findsOneWidget);
      expect(find.textContaining('2 genres'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('viewed-filter-clear-advanced')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disliked TV'), findsOneWidget);
      expect(states.movies.selectedRates, {MovieRate.notLiked});
      expect(states.movies.hasViewedAdvancedFilters, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'advanced filter sheet stays reachable on medium and large phones',
    (tester) async {
      final states = await _testStates([
        _movie('movie', 'Movie', MovieRate.liked),
        _movie(
          'tv',
          'TV show',
          MovieRate.okay,
          movieType: MovieType.tv,
          genres: const ['Comedy', 'Drama'],
        ),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final configuration in const [
        (Size(390, 844), 1.0),
        (Size(430, 932), 1.3),
      ]) {
        await tester.binding.setSurfaceSize(configuration.$1);
        await _pumpLibrary(
          tester,
          states,
          size: configuration.$1,
          textScale: configuration.$2,
        );
        await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('viewed-advanced-filters')));
        await tester.pumpAndSettle();

        expect(
          tester
              .getSize(
                find.byKey(const Key('viewed-advanced-filter-apply')),
              )
              .height,
          greaterThanOrEqualTo(48),
        );
        expect(find.text('Movies'), findsOneWidget);
        expect(find.text('TV'), findsOneWidget);
        expect(find.text('Comedy'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(
          find.byKey(const Key('viewed-advanced-filter-close')),
        );
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'back and scrim dismiss advanced drafts without applying',
    (tester) async {
      final states = await _testStates([
        _movie('movie', 'Movie', MovieRate.liked),
        _movie(
          'tv',
          'TV show',
          MovieRate.liked,
          movieType: MovieType.tv,
        ),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pumpLibrary(
        tester,
        states,
        size: const Size(390, 844),
        textScale: 1,
      );
      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('viewed-advanced-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('viewed-media-movies')));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('viewed-advanced-filter-sheet')), findsNothing);
      expect(states.movies.hasViewedAdvancedFilters, isFalse);

      await tester.tap(find.byKey(const Key('viewed-advanced-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('viewed-media-tv')));
      final sheetTop = tester
          .getTopLeft(find.byKey(const Key('viewed-advanced-filter-sheet')))
          .dy;
      expect(sheetTop, greaterThan(0));
      await tester.tapAt(Offset(20, sheetTop / 2));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('viewed-advanced-filter-sheet')), findsNothing);
      expect(states.movies.hasViewedAdvancedFilters, isFalse);
      expect(find.text('Movie'), findsOneWidget);
      expect(find.text('TV show'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('advanced filtering stays local and fast for a 240-title library',
      () async {
    final movies = List<Movie>.generate(
      240,
      (index) => _movie(
        'rated-$index',
        'Rated title $index',
        MovieRate.liked,
        movieType: index.isEven ? MovieType.movie : MovieType.tv,
        genres: [index % 3 == 0 ? 'Drama' : 'Comedy'],
      ),
    );
    final states = await _testStates(movies);
    addTearDown(states.movies.dispose);
    addTearDown(states.user.dispose);

    final stopwatch = Stopwatch()..start();
    states.movies.applyViewedAdvancedFilters(
      mediaType: MovieType.tv,
      genres: const ['Drama'],
    );
    stopwatch.stop();

    expect(states.movies.viewedMovies, hasLength(40));
    expect(
      states.movies.viewedMovies.every(
        (movie) =>
            movie.movieType == MovieType.tv && movie.genres.contains('Drama'),
      ),
      isTrue,
    );
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
  });

  testWidgets(
    'three-digit filter counts remain scrollable at compact text scale two',
    (tester) async {
      final movies = List<Movie>.generate(
        101,
        (index) => _movie(
          'liked-$index',
          'Liked film $index',
          MovieRate.liked,
        ),
      );
      final states = await _testStates(movies);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await _pumpLibrary(
        tester,
        states,
        size: const Size(320, 568),
        textScale: 2,
      );

      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(find.text('All 101'), findsOneWidget);
      expect(find.text('Liked 101'), findsOneWidget);
      expect(find.byKey(const Key('viewed-filter-scroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh failure is explicit and cached rows stay available',
    (tester) async {
      final states = await _testStates([
        _movie('saved', 'Saved for later', MovieRate.addedToWatchlist),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 640));
      var retries = 0;

      await _pumpLibrary(
        tester,
        states,
        size: const Size(360, 640),
        textScale: 1,
        refreshError: 'MovieDiary could not refresh your library.',
        onRetry: () async => retries += 1,
      );

      expect(find.text('Showing saved movies'), findsOneWidget);
      expect(find.text('Saved for later'), findsOneWidget);
      await tester.tap(find.byTooltip('Retry'));
      await tester.pump();
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tab progress owns segment selection and every page keeps its row mode',
    (tester) async {
      final states = await _testStates([
        _movie(
          'watchlist-row',
          'Saved for later',
          MovieRate.addedToWatchlist,
        ),
        _movie('viewed-row', 'Already watched', MovieRate.okay),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pumpLibrary(
        tester,
        states,
        size: const Size(390, 844),
        textScale: 1,
      );

      final libraryState = tester.state<MovieListState>(find.byType(MovieList));
      final watchlistRow = find.byKey(
        const Key('library-watchlist-watchlist-row'),
        skipOffstage: false,
      );

      expect(watchlistRow, findsOneWidget);
      expect(
        find.descendant(
          of: watchlistRow,
          matching: find.text('Mark watched'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      final viewedRow = find.byKey(
        const Key('library-viewed-viewed-row'),
        skipOffstage: false,
      );
      expect(viewedRow, findsOneWidget);
      expect(
        find.descendant(
          of: viewedRow,
          matching: find.text('Mark watched'),
          skipOffstage: false,
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: viewedRow,
          matching: find.text('Okay'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('viewed-filter-scroll')), findsOneWidget);

      await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
      await tester.pumpAndSettle();
      expect(libraryState.tabController.index, 0);

      libraryState.tabController.offset = 0.25;
      await tester.pump();
      expect(find.byKey(const Key('viewed-filter-scroll')), findsNothing);

      libraryState.tabController.offset = 0.5;
      await tester.pump();
      expect(find.byKey(const Key('viewed-filter-scroll')), findsOneWidget);

      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(libraryState.tabController.index, 1);
      expect(
        find.descendant(
          of: viewedRow,
          matching: find.text('Mark watched'),
          skipOffstage: false,
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
      await tester.pumpAndSettle();
      expect(libraryState.tabController.index, 0);

      libraryState.tabController.offset = 0.75;
      await tester.pump();
      expect(find.byKey(const Key('viewed-filter-scroll')), findsOneWidget);

      libraryState.tabController.offset = 0.25;
      await tester.pump();
      expect(find.byKey(const Key('viewed-filter-scroll')), findsNothing);

      libraryState.tabController.offset = 0;
      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(libraryState.tabController.index, 1);

      libraryState.tabController.offset = -0.25;
      await tester.pump();
      expect(find.byKey(const Key('viewed-filter-scroll')), findsOneWidget);

      libraryState.tabController.offset = -0.75;
      await tester.pump();
      expect(find.byKey(const Key('viewed-filter-scroll')), findsNothing);

      await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
      await tester.pumpAndSettle();
      expect(libraryState.tabController.index, 0);
      expect(
        find.descendant(
          of: watchlistRow,
          matching: find.text('Mark watched'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(libraryState.tabController.index, 1);

      libraryState.tabController.offset = -0.25;
      await tester.pump();
      expect(find.byKey(const Key('viewed-filter-scroll')), findsOneWidget);

      libraryState.tabController.offset = 0;
      await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pump();
      expect(find.byKey(const Key('viewed-filter-scroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Mark watched mutation moves between explicitly keyed row contexts',
    (tester) async {
      final savedMovie = _movie(
        'move-row',
        'Move this movie',
        MovieRate.addedToWatchlist,
      );
      final states = await _testStates([
        savedMovie,
        _movie(
          'stay-row',
          'Keep this saved',
          MovieRate.addedToWatchlist,
        ),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pumpLibrary(
        tester,
        states,
        size: const Size(390, 844),
        textScale: 1,
      );

      await states.movies.changeMovieRate(
        savedMovie.id,
        MovieRate.okay,
        false,
        savedMovie,
      );
      await tester.pump();

      final removingWatchlistRow = find.byKey(
        const Key('library-watchlist-move-row'),
        skipOffstage: false,
      );
      expect(removingWatchlistRow, findsOneWidget);
      expect(
        find.descendant(
          of: removingWatchlistRow,
          matching: find.text('Mark watched'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
      expect(removingWatchlistRow, findsNothing);
      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();

      final viewedRow = find.byKey(
        const Key('library-viewed-move-row'),
        skipOffstage: false,
      );
      expect(viewedRow, findsOneWidget);
      expect(
        find.descendant(of: viewedRow, matching: find.text('Okay')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: viewedRow, matching: find.text('Mark watched')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<_TestStates> _testStates(List<Movie> movies) async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'guest-access',
    'refreshToken': 'guest-refresh',
    'userId': 'guest-my-movies-test',
    'isIncognitoMode': 'true',
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  final movieState = MoviesState(storage: storage);
  await movieState.cacheInitialization;
  movieState.setInitialUserMovies(movies);
  return _TestStates(user: user, movies: movieState);
}

Future<void> _pumpLibrary(
  WidgetTester tester,
  _TestStates states, {
  required Size size,
  required double textScale,
  VoidCallback? onOpenDiscover,
  VoidCallback? onStartRating,
  String? refreshError,
  Future<void> Function()? onRetry,
  GlobalKey<MovieListState>? movieListKey,
}) {
  return tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserState>.value(value: states.user),
        ChangeNotifierProvider<MoviesState>.value(value: states.movies),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: MovieList(
          key: movieListKey,
          onOpenDiscover: onOpenDiscover ?? () {},
          onStartRating: onStartRating ?? () {},
          refreshError: refreshError,
          onRetry: onRetry,
        ),
      ),
    ),
  );
}

Future<void> _tapViewedFilter(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.descendant(
      of: find.byKey(const Key('viewed-filter-scroll')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Movie _movie(
  String id,
  String title,
  int movieRate, {
  MovieType movieType = MovieType.movie,
  List<String> genres = const ['Drama'],
}) {
  return Movie(
    id: id,
    title: title,
    overview: 'A useful movie synopsis.',
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
    genres: genres,
    movieRate: movieRate,
    movieType: movieType,
    releaseDate: DateTime(2024),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8,
    imdbVotes: 1000,
  );
}

class _TestStates {
  final UserState user;
  final MoviesState movies;

  const _TestStates({
    required this.user,
    required this.movies,
  });
}
