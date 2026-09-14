import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/mark_watched_bottom_sheet.dart';
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
    'Mark Watched shows one combined Undo and restores Watchlist durably',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final configuration in const [
        (Size(390, 844), 1.0),
      ]) {
        final harness = await _createHarness(isIncognito: true);
        try {
          await tester.binding.setSurfaceSize(configuration.$1);
          await _pumpLauncher(
            tester,
            harness,
            textScale: configuration.$2,
          );

          await tester.tap(find.text('Mark Watched'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Okay'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));

          expect(
            find.text('Rated Okay · Moved to Viewed'),
            findsOneWidget,
          );
          expect(find.text('Undo'), findsOneWidget);
          expect(
            find.byTooltip('Dismiss notification'),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('movie-diary-action-snackbar-icon')),
            findsOneWidget,
          );
          expect(harness.movie.movieRate, MovieRate.okay);
          expect(harness.movies.ratingStateVersion, 1);

          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Undo'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(harness.movie.movieRate, MovieRate.addedToWatchlist);
          expect(harness.movies.ratingStateVersion, 2);
          expect(
            find.text('Undo complete · Restored to Watchlist.'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          final cachedMovies = jsonDecode(
            (await harness.storage.read(key: 'movies'))!,
          ) as List<dynamic>;
          expect(cachedMovies, hasLength(1));
          expect(cachedMovies.single['movieRate'], MovieRate.addedToWatchlist);
        } finally {
          harness.dispose();
        }
      }
    },
  );

  testWidgets(
      'failed signed-in save rolls back without advancing cache version',
      (tester) async {
    final service = _RatingServiceAgent(responses: [http.Response('', 500)]);
    final harness = await _createHarness(
      isIncognito: false,
      serviceAgent: service,
    );
    addTearDown(harness.dispose);
    await _pumpLauncher(tester, harness);

    await tester.tap(find.text('Mark Watched'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.calls, [MovieRate.liked]);
    expect(harness.movie.movieRate, MovieRate.addedToWatchlist);
    expect(harness.movies.ratingStateVersion, 0);
    expect(find.text('Couldn’t update The Matrix. Try again.'), findsOneWidget);
    expect(find.text('How was it?'), findsOneWidget);
  });

  testWidgets('failed Undo keeps the saved opinion truthfully', (tester) async {
    final service = _RatingServiceAgent(
      responses: [http.Response('', 200), http.Response('', 503)],
    );
    final harness = await _createHarness(
      isIncognito: false,
      serviceAgent: service,
    );
    addTearDown(harness.dispose);
    await _pumpLauncher(tester, harness);

    await tester.tap(find.text('Mark Watched'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disliked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(service.calls, [MovieRate.notLiked, MovieRate.addedToWatchlist]);
    expect(harness.movie.movieRate, MovieRate.notLiked);
    expect(harness.movies.ratingStateVersion, 1);
    expect(
      find.text('Couldn’t undo. The Matrix remains in Viewed as Disliked.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'accessible Dismiss keeps the saved opinion without invoking Undo',
    (tester) async {
      final harness = await _createHarness(isIncognito: true);
      addTearDown(harness.dispose);
      await _pumpLauncher(
        tester,
        harness,
        textScale: 1.3,
        accessibleNavigation: true,
      );

      await tester.tap(find.text('Mark Watched'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Liked'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 5));

      expect(find.text('Rated Liked · Moved to Viewed'), findsOneWidget);
      expect(harness.movie.movieRate, MovieRate.liked);
      expect(harness.movies.ratingStateVersion, 1);

      await tester.tap(
        find.byKey(const Key('movie-diary-action-snackbar-dismiss')),
      );
      await tester.pumpAndSettle();

      expect(harness.movie.movieRate, MovieRate.liked);
      expect(harness.movies.ratingStateVersion, 1);
      expect(find.textContaining('Undo complete'), findsNothing);
      expect(find.text('Rated Liked · Moved to Viewed'), findsNothing);
    },
  );

  testWidgets('global movie guard blocks a concurrent screen copy',
      (tester) async {
    final response = Completer<http.Response>();
    final service = _RatingServiceAgent(completer: response);
    final harness = await _createHarness(
      isIncognito: false,
      serviceAgent: service,
    );
    addTearDown(harness.dispose);
    await _pumpLauncher(tester, harness);

    await tester.tap(find.text('Mark Watched'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Okay'));
    await tester.pump();

    expect(harness.movies.isMovieMutationActive(harness.movie.id), isTrue);
    expect(harness.movies.beginMovieMutation(harness.movie.id), isFalse);
    expect(service.calls, [MovieRate.okay]);

    response.complete(http.Response('', 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.movies.isMovieMutationActive(harness.movie.id), isFalse);
    expect(find.text('Rated Okay · Moved to Viewed'), findsOneWidget);
  });

  testWidgets('queued guest rating survives offline process recreation',
      (tester) async {
    final service = _RatingServiceAgent(offline: true);
    final harness = await _createHarness(
      isIncognito: true,
      serviceAgent: service,
    );
    await _pumpLauncher(tester, harness);

    await tester.tap(find.text('Mark Watched'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(harness.movie.movieRate, MovieRate.liked);
    expect(harness.movies.pendingAnonymousRatingSyncCount, 1);

    final restarted = MoviesState(
      storage: harness.storage,
      serviceAgent: service,
    );
    await restarted.cacheInitialization;
    await restarted.setCachedPendingAnonymousRatingSyncs();

    expect(restarted.userMovies.single.movieRate, MovieRate.liked);
    expect(restarted.pendingAnonymousRatingSyncCount, 1);
    restarted.dispose();
    harness.dispose();
  });
}

Future<_Harness> _createHarness({
  required bool isIncognito,
  _RatingServiceAgent? serviceAgent,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'watch-lifecycle-access',
    'refreshToken': 'watch-lifecycle-refresh',
    'userId': 'watch-lifecycle-user',
    'isIncognitoMode': 'true',
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  user.isIncognitoMode = isIncognito;
  final service = serviceAgent ?? _RatingServiceAgent();
  final movies = MoviesState(storage: storage, serviceAgent: service);
  await movies.cacheInitialization;
  final movie = _movie();
  movies.setInitialUserMovies([movie]);
  return _Harness(
    storage: storage,
    user: user,
    movies: movies,
    movie: movie,
    serviceAgent: service,
  );
}

Future<void> _pumpLauncher(
  WidgetTester tester,
  _Harness harness, {
  double textScale = 1,
  bool accessibleNavigation = false,
}) {
  return tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserState>.value(value: harness.user),
        ChangeNotifierProvider<MoviesState>.value(value: harness.movies),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            accessibleNavigation: accessibleNavigation,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showMarkWatchedBottomSheet(
                  context: context,
                  movie: harness.movie,
                  serviceAgent: harness.serviceAgent,
                ),
                child: const Text('Mark Watched'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Movie _movie() {
  return Movie(
    id: 'watch-lifecycle-matrix',
    title: 'The Matrix',
    overview: 'A useful movie synopsis.',
    tagline: null,
    posterPath: '',
    duration: 136,
    rating: 85,
    allVotes: 100,
    likedVotes: 85,
    dislikedVotes: 15,
    countries: 'US',
    actors: const ['Keanu Reeves'],
    directors: const ['Lana Wachowski', 'Lilly Wachowski'],
    genres: const ['Action', 'Science Fiction'],
    movieRate: MovieRate.addedToWatchlist,
    movieType: MovieType.movie,
    releaseDate: DateTime(1999),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8.7,
    imdbVotes: 2100000,
    updated: DateTime.utc(2026, 8, 1),
  );
}

class _Harness {
  const _Harness({
    required this.storage,
    required this.user,
    required this.movies,
    required this.movie,
    required this.serviceAgent,
  });

  final FlutterSecureStorage storage;
  final UserState user;
  final MoviesState movies;
  final Movie movie;
  final _RatingServiceAgent serviceAgent;

  void dispose() {
    movies.dispose();
    user.dispose();
  }
}

class _RatingServiceAgent extends ServiceAgent {
  _RatingServiceAgent({
    this.responses = const [],
    this.completer,
    this.offline = false,
  });

  final List<http.Response> responses;
  final Completer<http.Response>? completer;
  final bool offline;
  final List<int> calls = [];

  @override
  Future<http.Response> rateMovie(
    String movieId,
    String userId,
    int movieRate,
  ) async {
    calls.add(movieRate);
    if (offline) {
      throw TimeoutException('offline');
    }
    if (completer != null) {
      return completer!.future;
    }
    if (responses.isEmpty) {
      return http.Response('', 200);
    }
    final index = (calls.length - 1).clamp(0, responses.length - 1).toInt();
    return responses[index];
  }
}
