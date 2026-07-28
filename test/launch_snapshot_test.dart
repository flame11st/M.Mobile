import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/launch_snapshot.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/discover_page.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('launch routing', () {
    test('authenticated sessions always open Discover', () {
      expect(
        resolveLaunchDestination(
          hasAuthenticatedSession: true,
          hasAnonymousProfile: false,
          onboardingStage: OnboardingStage.rating,
        ),
        LaunchDestination.discover,
      );
    });

    test('anonymous rating stage resumes Rate Movies', () {
      expect(
        resolveLaunchDestination(
          hasAuthenticatedSession: false,
          hasAnonymousProfile: true,
          onboardingStage: OnboardingStage.rating,
        ),
        LaunchDestination.rateMovies,
      );
    });

    test('completed and skipped anonymous sessions open Discover', () {
      for (final stage in [
        OnboardingStage.completed,
        OnboardingStage.skipped,
        OnboardingStage.none,
      ]) {
        expect(
          resolveLaunchDestination(
            hasAuthenticatedSession: false,
            hasAnonymousProfile: true,
            onboardingStage: stage,
          ),
          LaunchDestination.discover,
        );
      }
    });

    test('missing profile requires anonymous bootstrap', () {
      expect(
        resolveLaunchDestination(
          hasAuthenticatedSession: false,
          hasAnonymousProfile: false,
          onboardingStage: OnboardingStage.none,
        ),
        LaunchDestination.bootstrapAnonymous,
      );
    });
  });

  test('launch snapshot round-trips nullable cached state', () {
    final refreshedAt = DateTime.utc(2026, 7, 26, 18, 30);
    final snapshot = LaunchSnapshot(
      userId: 'guest-1',
      isIncognitoMode: true,
      hasCredentials: true,
      onboardingStage: OnboardingStage.completed,
      ratedMoviesCount: 11,
      lastSuccessfulLibraryRefreshAt: refreshedAt,
    );

    final decoded = LaunchSnapshot.fromJson(
      jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>,
    );

    expect(decoded.userId, 'guest-1');
    expect(decoded.isIncognitoMode, isTrue);
    expect(decoded.hasCredentials, isTrue);
    expect(decoded.onboardingStage, OnboardingStage.completed);
    expect(decoded.ratedMoviesCount, 11);
    expect(decoded.lastSuccessfulLibraryRefreshAt, refreshedAt);
  });

  test('legacy anonymous onboarding state migrates into launch snapshot',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'token': 'access',
      'refreshToken': 'refresh',
      'userId': 'guest-legacy',
      'isIncognitoMode': 'true',
      'onboardingStarted': 'true',
      'onboardingCompleted': 'true',
      'onboardingSkipped': 'false',
    });

    const storage = FlutterSecureStorage();
    final state = UserState(storage: storage);
    await state.initialization;

    expect(state.isUserAuthorizedOrInIncognitoMode, isTrue);
    expect(state.onboardingStage, OnboardingStage.completed);
    expect(state.launchDestination, LaunchDestination.discover);

    final encodedSnapshot =
        await storage.read(key: UserState.launchSnapshotKey);
    final snapshot = LaunchSnapshot.fromJson(
      jsonDecode(encodedSnapshot!) as Map<String, dynamic>,
    );
    expect(snapshot.userId, 'guest-legacy');
    expect(snapshot.onboardingStage, OnboardingStage.completed);
  });

  test('cached movies hydrate before startup routing uses their count',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'movies': jsonEncode([
        _movie(id: 'liked', movieRate: MovieRate.liked),
        _movie(id: 'okay', movieRate: MovieRate.okay),
        _movie(id: 'watchlist', movieRate: MovieRate.addedToWatchlist),
      ]),
    });

    int? observedRatedCount;
    final state = MoviesState(
      storage: const FlutterSecureStorage(),
      onRatedMoviesCountChanged: (count) {
        observedRatedCount = count;
      },
    );

    await state.cacheInitialization;

    expect(state.hasCachedUserMoviesSnapshot, isTrue);
    expect(state.isCachedMoviesLoaded, isTrue);
    expect(state.userMovies, hasLength(3));
    expect(observedRatedCount, 2);
  });

  testWidgets(
      'offline Discover preserves cached taste progress on compact phone',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    await userState.setCachedRatedMoviesCount(11);
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserState>.value(value: userState),
          ChangeNotifierProvider<MoviesState>.value(value: moviesState),
        ],
        child: MaterialApp(
          home: DiscoverPage(
            isOffline: true,
            onRetry: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text("You're offline. Your saved movies are still here."),
      findsOneWidget,
    );
    expect(find.text('Your taste profile'), findsOneWidget);
    expect(
      find.text('Ready · improves as you rate more'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Movie _movie({
  required String id,
  required int movieRate,
}) {
  return Movie(
    id: id,
    title: 'Movie $id',
    overview: '',
    tagline: null,
    posterPath: '',
    duration: 100,
    rating: 80,
    allVotes: 10,
    likedVotes: 8,
    dislikedVotes: 2,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Drama'],
    movieRate: movieRate,
    movieType: MovieType.movie,
    releaseDate: DateTime(2020),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8,
    imdbVotes: 100,
  );
}
