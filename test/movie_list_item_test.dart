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
import 'package:mmobile/Widgets/mark_watched_bottom_sheet.dart';
import 'package:mmobile/Widgets/movie_list_item.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('movie row system has no overflow across the target matrix',
      (tester) async {
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const sizes = [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
    ];
    const scales = [1.0, 1.3, 2.0];
    const configurations = [
      ('browse', MovieCardMode.browse),
      ('watchlist', MovieCardMode.watchlist),
      ('viewed', MovieCardMode.viewed),
      ('personal', MovieCardMode.personalList),
    ];

    for (final size in sizes) {
      for (final scale in scales) {
        for (final configuration in configurations) {
          await tester.binding.setSurfaceSize(size);
          await _pumpRow(
            tester,
            states,
            movieId: configuration.$1,
            mode: configuration.$2,
            textScale: scale,
          );

          if (configuration.$2 == MovieCardMode.watchlist) {
            expect(find.text('Mark watched'), findsOneWidget);
            expect(find.text('Mark\nWatched'), findsNothing);
          } else {
            expect(find.text('Mark watched'), findsNothing);
          }
          expect(find.byTooltip('Movie actions'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: '${configuration.$1} at $size / text scale $scale',
          );
        }
      }
    }
  });

  testWidgets('row action target opens one independent scroll-safe sheet',
      (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    final observer = _CountingNavigatorObserver();

    await _pumpRow(
      tester,
      states,
      movieId: 'browse',
      mode: MovieCardMode.browse,
      textScale: 2,
      observer: observer,
    );
    final pushesBeforeAction = observer.pushCount;

    expect(
      find.bySemanticsLabel(
        'Open A deliberately long translated movie title for layout testing '
        'details',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Movie actions'), findsOneWidget);

    await tester.tap(find.byTooltip('Movie actions').first);
    await tester.pumpAndSettle();

    expect(observer.pushCount, pushesBeforeAction + 1);
    expect(find.text('Movie actions'), findsOneWidget);
    expect(find.text('Add to Watchlist'), findsOneWidget);
    expect(find.text('Rate now'), findsOneWidget);
    expect(find.text('Create a personal list'), findsOneWidget);
    expect(find.text('Open details'), findsOneWidget);
    expect(find.byType(Md3BottomSheetSurface), findsOneWidget);
    expect(tester.takeException(), isNull);
    semanticsHandle.dispose();
  });

  testWidgets('browse row adds directly to an existing personal list',
      (tester) async {
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await states.movies.setInitialMoviesLists([
      MoviesList(
        name: 'Weekend Picks',
        order: 1,
        listMovies: [],
        movieListType: MovieListType.personal,
      ),
    ]);
    await tester.binding.setSurfaceSize(const Size(360, 640));

    await _pumpRow(
      tester,
      states,
      movieId: 'browse',
      mode: MovieCardMode.browse,
      textScale: 1,
    );

    await tester.tap(find.byTooltip('Movie actions'));
    await tester.pumpAndSettle();
    expect(find.text('Add to personal list'), findsOneWidget);

    await tester.tap(find.text('Add to personal list'));
    await tester.pumpAndSettle();
    expect(find.text('Weekend Picks'), findsOneWidget);

    await tester.ensureVisible(find.text('Weekend Picks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekend Picks'));
    await tester.pumpAndSettle();

    expect(
      states.movies.personalMoviesLists.single.listMovies
          .map((movie) => movie.id),
      contains('browse'),
    );
    expect(find.text('Added to Weekend Picks.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('Mark Watched presenter keeps every action scroll reachable',
      (tester) async {
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final movie = states.movies.userMovies
        .firstWhere((movie) => movie.movieRate == MovieRate.addedToWatchlist);

    const sizes = [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
    ];
    const scales = [1.0, 1.3, 2.0];

    for (final size in sizes) {
      for (final scale in scales) {
        await tester.binding.setSurfaceSize(size);
        await _pumpSheetLauncher(
          tester,
          states,
          movie: movie,
          textScale: scale,
        );

        await tester.tap(find.text('Open Mark Watched'));
        await tester.pumpAndSettle();

        expect(find.text('How was it?'), findsOneWidget);
        expect(find.text('Liked'), findsOneWidget);
        expect(find.text('Okay'), findsOneWidget);
        expect(find.text('Disliked'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.byType(Md3BottomSheetSurface), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(
            tester.getRect(find.text('Cancel')).bottom, lessThan(size.height));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    }
  });
}

Future<_TestStates> _testStates() async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'guest-access',
    'refreshToken': 'guest-refresh',
    'userId': 'guest-row-test',
    'isIncognitoMode': 'true',
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  final movies = MoviesState(storage: storage);
  await movies.cacheInitialization;
  movies.setInitialUserMovies([
    _movie(
      id: 'browse',
      title: 'A deliberately long translated movie title for layout testing',
      movieRate: MovieRate.notRated,
    ),
    _movie(
      id: 'watchlist',
      title: 'The Matrix',
      movieRate: MovieRate.addedToWatchlist,
    ),
    _movie(
      id: 'viewed',
      title: 'A very long viewed movie title that needs two stable lines',
      movieRate: MovieRate.liked,
    ),
    _movie(
      id: 'personal',
      title: 'Personal list movie',
      movieRate: MovieRate.okay,
    ),
  ]);

  return _TestStates(user: user, movies: movies);
}

Future<void> _pumpRow(
  WidgetTester tester,
  _TestStates states, {
  required String movieId,
  required MovieCardMode mode,
  required double textScale,
  NavigatorObserver? observer,
}) {
  return tester.pumpWidget(
    _app(
      states,
      textScale: textScale,
      observer: observer,
      home: Scaffold(
        backgroundColor: Md3Colors.background,
        body: SingleChildScrollView(
          child: MovieListItem(
            movie: states.movies.userMovies
                .firstWhere((movie) => movie.id == movieId),
            mode: mode,
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpSheetLauncher(
  WidgetTester tester,
  _TestStates states, {
  required Movie movie,
  required double textScale,
}) {
  return tester.pumpWidget(
    _app(
      states,
      textScale: textScale,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showMarkWatchedBottomSheet(
                context: context,
                movie: movie,
              ),
              child: const Text('Open Mark Watched'),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _app(
  _TestStates states, {
  required Widget home,
  required double textScale,
  NavigatorObserver? observer,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserState>.value(value: states.user),
      ChangeNotifierProvider<MoviesState>.value(value: states.movies),
    ],
    child: MaterialApp(
      navigatorObservers: [
        if (observer != null) observer,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: home,
    ),
  );
}

Movie _movie({
  required String id,
  required String title,
  required int movieRate,
}) {
  return Movie(
    id: id,
    title: title,
    overview: 'A useful movie synopsis.',
    tagline: null,
    posterPath: '',
    duration: 136,
    rating: 85,
    allVotes: 100,
    likedVotes: 85,
    dislikedVotes: 15,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Action', 'Science Fiction', 'Adventure'],
    movieRate: movieRate,
    movieType: MovieType.movie,
    releaseDate: DateTime(1999),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8.7,
    imdbVotes: 100000,
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

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    super.didPush(route, previousRoute);
  }
}
