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

      await tester.tap(find.byKey(const Key('viewed-filter-okay')));
      await tester.pumpAndSettle();
      expect(find.text('Okay film'), findsOneWidget);
      expect(find.text('Liked film'), findsNothing);

      await tester.tap(find.byKey(const Key('my-movies-tab-watchlist')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('my-movies-tab-viewed')));
      await tester.pumpAndSettle();
      expect(find.text('Okay film'), findsOneWidget);
      expect(find.text('Liked film'), findsNothing);

      await tester.drag(
        find.byKey(const Key('viewed-filter-scroll')),
        const Offset(-260, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('viewed-filter-disliked')));
      await tester.pumpAndSettle();
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
          onOpenDiscover: onOpenDiscover ?? () {},
          onStartRating: onStartRating ?? () {},
          refreshError: refreshError,
          onRetry: onRetry,
        ),
      ),
    ),
  );
}

Movie _movie(String id, String title, int movieRate) {
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
    genres: const ['Drama'],
    movieRate: movieRate,
    movieType: MovieType.movie,
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
