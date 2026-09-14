import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Objects/user_taste_profile.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/discover_page.dart';
import 'package:mmobile/Widgets/movies_list_page.dart';
import 'package:mmobile/Widgets/onboarding_wizard_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Discover Show all actions stack and open the exact source list',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final userState = UserState(storage: storage);
      await userState.initialization;
      final moviesState = MoviesState(storage: storage);
      await moviesState.cacheInitialization;
      addTearDown(moviesState.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const sizes = [
        Size(320, 568),
        Size(360, 640),
        Size(390, 844),
        Size(430, 932),
      ];
      const scales = [1.0, 1.3, 2.0];

      for (final size in sizes) {
        for (final scale in scales) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await tester.binding.setSurfaceSize(size);
          await _pumpDiscover(
            tester,
            userState,
            moviesState,
            textScale: scale,
            viewportSize: size,
            onOpenLists: () {},
          );

          final titleFinder = find.byKey(
            const ValueKey('discover-section-title-Popular Movies'),
          );
          final actionFinder = find.byKey(
            const ValueKey('discover-section-action-Popular Movies'),
          );
          await tester.ensureVisible(titleFinder);
          await tester.ensureVisible(actionFinder);
          await tester.pump();

          final titleWidget = tester.widget<Text>(titleFinder);
          expect(titleWidget.maxLines, 2);
          expect(titleWidget.overflow, TextOverflow.ellipsis);
          expect(tester.getSize(actionFinder).height, greaterThanOrEqualTo(44));

          if (size.width <= 390 && scale >= 1.3) {
            final titleRect = tester.getRect(titleFinder);
            final actionRect = tester.getRect(actionFinder);
            expect(actionRect.top, greaterThanOrEqualTo(titleRect.bottom + 7));
            expect(
              (actionRect.left - titleRect.left).abs(),
              lessThanOrEqualTo(1),
            );
          }

          await tester.tap(actionFinder);
          await tester.pumpAndSettle();
          expect(find.byType(MoviesListPage), findsOneWidget);
          expect(find.text('Popular Movies (TMDb)'), findsOneWidget);
          expect(find.byTooltip('Back to Discover'), findsOneWidget);
          await tester.tap(find.byTooltip('Back to Discover'));
          await tester.pumpAndSettle();
          expect(find.byType(DiscoverPage), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('Discover medium larger-text section visual golden', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
    addTearDown(moviesState.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pumpDiscover(
      tester,
      userState,
      moviesState,
      textScale: 1.2,
      viewportSize: const Size(390, 844),
      onOpenLists: () {},
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('discover-section-title-Popular Movies')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('discover-section-action-Popular Movies')),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('discover-golden')),
      matchesGoldenFile('goldens/uxr18-discover-390x844-1.2x.png'),
    );
  });

  testWidgets('ready taste state keeps the same large-text header geometry', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
    moviesState.setInitialUserMovies([
      for (var index = 0; index < 10; index++) _ratedMovie(index),
    ]);
    addTearDown(moviesState.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(360, 640));
    await _pumpDiscover(
      tester,
      userState,
      moviesState,
      textScale: 2,
      viewportSize: const Size(360, 640),
      onOpenLists: () {},
    );

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Your MovieDNA'), findsOneWidget);
    final titleFinder = find.byKey(
      const ValueKey('discover-section-title-Popular Movies'),
    );
    final actionFinder = find.byKey(
      const ValueKey('discover-section-action-Popular Movies'),
    );
    await tester.ensureVisible(actionFinder);
    await tester.pump();

    expect(
      tester.getRect(actionFinder).top,
      greaterThanOrEqualTo(tester.getRect(titleFinder).bottom + 7),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('taste profile stays consolidated below at and above readiness', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const scenarios = [
      (count: 0, size: Size(390, 844), textScale: 1.0),
      (count: 10, size: Size(390, 844), textScale: 1.0),
      (count: 11, size: Size(430, 930), textScale: 1.3),
    ];

    for (final scenario in scenarios) {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final userState = UserState(storage: storage);
      await userState.initialization;
      final moviesState = MoviesState(storage: storage);
      await moviesState.cacheInitialization;
      moviesState.setInitialUserMovies([
        for (var index = 0; index < scenario.count; index++) _ratedMovie(index),
      ]);

      await tester.binding.setSurfaceSize(scenario.size);
      await _pumpDiscover(
        tester,
        userState,
        moviesState,
        textScale: scenario.textScale,
        viewportSize: scenario.size,
        onOpenLists: () {},
      );

      final profileTitles = [
        ...find.text('Build your taste profile').evaluate(),
        ...find.text('Your MovieDNA').evaluate(),
      ];
      expect(profileTitles, hasLength(1));
      expect(find.text('Taste profile ready'), findsNothing);

      if (scenario.count < 10) {
        expect(find.text('${scenario.count}/10'), findsOneWidget);
        expect(find.text('Rate Movies'), findsOneWidget);
        expect(find.text('Get Recommendations'), findsNothing);
      } else {
        expect(find.text('${scenario.count} rated'), findsOneWidget);
        expect(find.text('Get Recommendations'), findsOneWidget);
        expect(find.text('Rate Movies'), findsNothing);
      }

      expect(
        tester.takeException(),
        isNull,
        reason: 'collapsed scenario: $scenario',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      moviesState.dispose();
    }
  });

  testWidgets('incomplete MovieDNA opens the first-ten rating flow', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
    moviesState.setInitialUserMovies([
      for (var index = 0; index < 9; index++) _ratedMovie(index),
    ]);
    addTearDown(moviesState.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _pumpDiscover(
      tester,
      userState,
      moviesState,
      textScale: 1,
      viewportSize: const Size(390, 844),
      onOpenLists: () {},
    );

    await tester.tap(find.text('Rate Movies'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingWizardPage), findsOneWidget);
    expect(find.text('Rate Movies'), findsOneWidget);
    expect(find.text('9 of 10 movies rated'), findsOneWidget);
    expect(find.text('Rate more'), findsNothing);
    expect(userState.onboardingStage, OnboardingStage.rating);
  });

  testWidgets('ready MovieDNA keeps the continuous Rate more flow', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    await userState.setOnboardingStage(OnboardingStage.completed);
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
    moviesState.setInitialUserMovies([
      for (var index = 0; index < 10; index++) _ratedMovie(index),
    ]);
    addTearDown(moviesState.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(430, 930));
    await _pumpDiscover(
      tester,
      userState,
      moviesState,
      textScale: 1.3,
      viewportSize: const Size(430, 930),
      onOpenLists: () {},
      tasteProfileOverride: Future.value(_richMovieDnaProfile),
    );
    await tester.pump();
    await tester.ensureVisible(find.textContaining('Taste details'));
    await tester.tap(find.textContaining('Taste details'));
    await tester.pump();
    await tester.ensureVisible(find.text('Rate more'));
    await tester.tap(find.text('Rate more'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingWizardPage), findsOneWidget);
    expect(find.text('Rate more'), findsOneWidget);
    expect(find.text('0 rated this session'), findsOneWidget);
    expect(find.textContaining('of 10 movies rated'), findsNothing);
    expect(userState.onboardingStage, OnboardingStage.completed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('under-10 taste progress stacks before compact text fragments', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
    addTearDown(moviesState.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(320, 568));
    await _pumpDiscover(
      tester,
      userState,
      moviesState,
      textScale: 2,
      viewportSize: const Size(320, 568),
      onOpenLists: () {},
    );

    final layoutFinder = find.byKey(const Key('taste-progress-action-layout'));
    final progressLabelFinder = find.byKey(const Key('taste-progress-label'));
    await tester.ensureVisible(layoutFinder);
    await tester.pump();

    expect(tester.widget(layoutFinder), isA<Column>());
    expect(tester.getSize(progressLabelFinder).width, greaterThan(180));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ready MovieDNA is compact, specific, editorial, and responsive',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final scenario in const [
        (size: Size(390, 844), textScale: 1.0),
        (size: Size(430, 930), textScale: 1.3),
      ]) {
        FlutterSecureStorage.setMockInitialValues({});
        const storage = FlutterSecureStorage();
        final userState = UserState(storage: storage);
        await userState.initialization;
        final moviesState = MoviesState(storage: storage);
        await moviesState.cacheInitialization;
        moviesState.setInitialUserMovies([
          for (var index = 0; index < 250; index++) _ratedMovie(index),
        ]);
        await tester.binding.setSurfaceSize(scenario.size);

        await _pumpDiscover(
          tester,
          userState,
          moviesState,
          textScale: scenario.textScale,
          viewportSize: scenario.size,
          onOpenLists: () {},
          tasteProfileOverride: Future.value(_richMovieDnaProfile),
        );
        await tester.pump();

        final card = find.byKey(const Key('moviedna-card'));
        expect(card, findsOneWidget);
        expect(find.text('Your MovieDNA'), findsOneWidget);
        expect(find.text('250 rated'), findsOneWidget);
        expect(find.textContaining('Your MovieDNA blends'), findsNothing);
        expect(find.text('Horror regular'), findsOneWidget);
        expect(find.text('Comedy favorite'), findsOneWidget);
        if (scenario.size.width >= 430) {
          expect(find.text('Global cinema explorer'), findsOneWidget);
        } else {
          expect(find.text('Global cinema explorer'), findsNothing);
        }
        expect(find.text('Cross-format regular'), findsNothing);
        expect(find.text('Very strong read · 250 ratings'), findsOneWidget);

        final primaryAction = find.ancestor(
          of: find.text('Get Recommendations'),
          matching: find.byType(FilledButton),
        );
        expect(tester.getSize(primaryAction).height, 56);
        if (scenario.textScale == 1.0) {
          expect(tester.getSize(card).height, 334);
        }
        await tester.ensureVisible(find.textContaining('Taste details'));
        await tester.pump();
        await tester.tap(find.textContaining('Taste details'));
        await tester.pump();
        expect(find.text('What your ratings reveal'), findsOneWidget);
        expect(
          tester.widget(
            find.byKey(const ValueKey('moviedna-insight-genre-horror')),
          ),
          isA<Padding>(),
        );
        expect(find.text('Show more insights'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        moviesState.dispose();
      }
    },
  );

  testWidgets('ready MovieDNA keeps loading and error states truthful', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
    moviesState.setInitialUserMovies([
      for (var index = 0; index < 10; index++) _ratedMovie(index),
    ]);
    addTearDown(moviesState.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    final errorCompleter = Completer<UserTasteProfile>();
    await _pumpDiscover(
      tester,
      userState,
      moviesState,
      textScale: 1,
      viewportSize: const Size(390, 844),
      onOpenLists: () {},
      tasteProfileOverride: Completer<UserTasteProfile>().future,
    );
    expect(find.text('Refreshing taste details…'), findsOneWidget);

    await _pumpDiscover(
      tester,
      userState,
      moviesState,
      textScale: 1,
      viewportSize: const Size(390, 844),
      onOpenLists: () {},
      tasteProfileOverride: errorCompleter.future,
    );
    errorCompleter.completeError(StateError('profile unavailable'));
    await tester.pump();
    await tester.pump();
    expect(
      find.textContaining('Connect to refresh your detailed taste signals'),
      findsOneWidget,
    );
    expect(find.text('Retry Taste Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDiscover(
  WidgetTester tester,
  UserState userState,
  MoviesState moviesState, {
  required double textScale,
  required Size viewportSize,
  required VoidCallback onOpenLists,
  Future<UserTasteProfile>? tasteProfileOverride,
}) async {
  if (!moviesState.isMoviesListsRequested) {
    moviesState.setExternalMoviesLists(_popularLists());
    moviesState.markMoviesListsRequestFinished();
  }
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserState>.value(value: userState),
        ChangeNotifierProvider<MoviesState>.value(value: moviesState),
      ],
      child: MaterialApp(
        theme: MovieDiaryTheme.light(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: viewportSize,
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          );
        },
        home: RepaintBoundary(
          key: const Key('discover-golden'),
          child: Material(
            color: Md3Colors.background,
            child: DiscoverPage(
              isOffline: true,
              onRetry: () async {},
              onOpenLists: onOpenLists,
              tasteProfileOverride: tasteProfileOverride,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _richMovieDnaProfile = UserTasteProfile(
  isReady: true,
  isGenerated: true,
  ratingsCount: 250,
  movieRatingsCount: 180,
  tvRatingsCount: 70,
  profileConfidencePercent: 94,
  recommendationAdvice: ['Try one mystery outside your usual decade.'],
  summaryText:
      'Your MovieDNA blends generic copy that the compact card should not repeat.',
  insights: [
    MovieDnaInsight(
      key: 'cross-format',
      label: 'Cross-format regular',
      description: 'Movies and TV both contribute favorites.',
      category: 'format',
      confidencePercent: 95,
      positiveEvidenceCount: 100,
      counterEvidenceCount: 0,
    ),
    MovieDnaInsight(
      key: 'genre-horror',
      label: 'Horror regular',
      description: 'Horror repeatedly earns your strongest reactions.',
      category: 'genre_franchise',
      confidencePercent: 91,
      positiveEvidenceCount: 38,
      counterEvidenceCount: 0,
    ),
    MovieDnaInsight(
      key: 'genre-comedy',
      label: 'Comedy favorite',
      description: 'Comedy is a dependable favorite in your history.',
      category: 'genre_franchise',
      confidencePercent: 89,
      positiveEvidenceCount: 34,
      counterEvidenceCount: 0,
    ),
    MovieDnaInsight(
      key: 'global-cinema',
      label: 'Global cinema explorer',
      description: 'Stories from many countries consistently rate well.',
      category: 'era_international',
      confidencePercent: 90,
      positiveEvidenceCount: 30,
      counterEvidenceCount: 0,
    ),
    MovieDnaInsight(
      key: 'international-language',
      label: 'International language explorer',
      description: 'International-language stories rate well.',
      category: 'era_international',
      confidencePercent: 85,
      positiveEvidenceCount: 20,
      counterEvidenceCount: 0,
    ),
    MovieDnaInsight(
      key: 'epic-runtime',
      label: 'Epic-runtime fan',
      description: 'Long-form stories repeatedly earn strong reactions.',
      category: 'mood_pacing',
      confidencePercent: 88,
      positiveEvidenceCount: 28,
      counterEvidenceCount: 0,
    ),
    MovieDnaInsight(
      key: 'mystery-investigation',
      label: 'Mystery solver',
      description: 'Investigations and puzzle-box stories keep working.',
      category: 'story_theme',
      confidencePercent: 87,
      positiveEvidenceCount: 24,
      counterEvidenceCount: 0,
    ),
  ],
);

List<MoviesList> _popularLists() {
  return [
    MoviesList(
      name: 'Popular Movies (TMDb)',
      order: 1,
      listMovies: [_browseMovie('tmdb-movie', MovieType.movie)],
      movieListType: MovieListType.external,
    ),
    MoviesList(
      name: 'Popular TV Series (TMDb)',
      order: 2,
      listMovies: [_browseMovie('tmdb-tv', MovieType.tv)],
      movieListType: MovieListType.external,
    ),
  ];
}

Movie _browseMovie(String id, MovieType type) {
  return Movie(
    id: id,
    title: type == MovieType.movie ? 'TMDb movie' : 'TMDb TV show',
    overview: 'Overview',
    tagline: null,
    posterPath: 'poster.jpg',
    duration: 110,
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

Movie _ratedMovie(int index) {
  return Movie(
    id: 'rated-$index',
    title: 'Rated movie $index',
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
    movieRate: MovieRate.liked,
    movieType: MovieType.movie,
    releaseDate: DateTime(2020),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8,
    imdbVotes: 100,
  );
}
