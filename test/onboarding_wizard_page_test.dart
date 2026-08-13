import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/onboarding_wizard_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tenth rating stays in onboarding and shows completion',
      (tester) async {
    final states = await _statesWithRatings(9);
    states.movies.setStarterDeckMovies([
      _movie(id: 'candidate-10', movieRate: MovieRate.notRated),
    ]);
    var finished = false;

    await _pumpWizard(
      tester,
      states,
      onFinished: () => finished = true,
    );

    expect(find.text('9 of 10 movies rated'), findsOneWidget);
    await tester.tap(find.text('Liked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Taste profile ready'), findsOneWidget);
    expect(find.text('Get Recommendations'), findsOneWidget);
    expect(find.text('Go to Discover'), findsOneWidget);
    expect(states.user.onboardingStage, OnboardingStage.rating);
    expect(finished, isFalse);

    await tester.tap(find.text('Go to Discover'));
    await tester.pumpAndSettle();

    expect(states.user.onboardingStage, OnboardingStage.completed);
    expect(states.user.onboardingCompleted, isTrue);
    expect(finished, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    states.movies.dispose();
  });

  testWidgets('Get Recommendations persists completion before routing',
      (tester) async {
    final states = await _statesWithRatings(10);
    addTearDown(states.movies.dispose);
    final exitEvents = <String>[];

    await _pumpWizard(
      tester,
      states,
      onExitStarted: () {
        exitEvents.add('started:${states.user.onboardingStage}');
      },
      onExitCompleted: () {
        exitEvents.add('completed:${states.user.onboardingStage}');
      },
      recommendationsBuilder: (_) => const Scaffold(
        body: Center(child: Text('Test Recommendations')),
      ),
    );

    await tester.tap(find.text('Get Recommendations'));
    await tester.pumpAndSettle();

    expect(states.user.onboardingStage, OnboardingStage.completed);
    expect(find.text('Test Recommendations'), findsOneWidget);
    expect(
      exitEvents,
      [
        'started:${OnboardingStage.rating}',
        'completed:${OnboardingStage.completed}',
      ],
    );

    final relaunched = UserState(storage: states.storage);
    await relaunched.initialization;
    expect(relaunched.onboardingStage, OnboardingStage.completed);
    expect(relaunched.launchDestination, LaunchDestination.discover);
  });

  testWidgets(
      'continuous mode opens an unrated candidate without rewriting completion',
      (tester) async {
    final states = await _statesWithRatings(
      50,
      onboardingStage: OnboardingStage.completed,
    );
    states.movies.setStarterDeckMovies([
      _movie(id: 'continuous-a', movieRate: MovieRate.notRated),
      _movie(id: 'continuous-b', movieRate: MovieRate.notRated),
    ]);
    var finished = false;

    await _pumpWizard(
      tester,
      states,
      mode: RatingFlowMode.continuous,
      onFinished: () => finished = true,
    );

    expect(find.text('Rate more'), findsOneWidget);
    expect(find.text('Movie continuous-a'), findsOneWidget);
    expect(find.text('Taste profile ready'), findsNothing);
    expect(find.text('MovieDNA is based on 50 ratings.'), findsOneWidget);
    expect(states.user.onboardingStage, OnboardingStage.completed);

    await tester.tap(find.text('Liked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Movie continuous-b'), findsOneWidget);
    expect(find.text('1 rated this session'), findsOneWidget);
    expect(states.user.onboardingStage, OnboardingStage.completed);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(finished, isTrue);
    expect(states.user.onboardingStage, OnboardingStage.completed);

    await tester.pumpWidget(const SizedBox.shrink());
    states.movies.dispose();
  });

  testWidgets('continuous skip paths do not count or repeat in-session',
      (tester) async {
    final states = await _statesWithRatings(
      10,
      onboardingStage: OnboardingStage.completed,
    );
    addTearDown(states.movies.dispose);
    states.movies.setStarterDeckMovies([
      _movie(id: 'skip-a', movieRate: MovieRate.notRated),
      _movie(id: 'skip-b', movieRate: MovieRate.notRated),
      _movie(id: 'skip-c', movieRate: MovieRate.notRated),
    ]);

    await _pumpWizard(
      tester,
      states,
      mode: RatingFlowMode.continuous,
    );

    await tester.tap(find.text("Haven't seen it"));
    await tester.pump();
    expect(find.text('Movie skip-b'), findsOneWidget);
    expect(find.text('0 rated this session'), findsOneWidget);

    await tester.tap(find.byTooltip('Skip this title'));
    await tester.pump();
    expect(find.text('Movie skip-c'), findsOneWidget);
    expect(find.text('Movie skip-a'), findsNothing);
    expect(find.text('Movie skip-b'), findsNothing);
    expect(find.text('0 rated this session'), findsOneWidget);
    expect(states.user.onboardingStage, OnboardingStage.completed);
  });

  testWidgets('continuous ready accounts always enter an eligible candidate',
      (tester) async {
    for (final count in const [10, 50, 200]) {
      final states = await _statesWithRatings(
        count,
        onboardingStage: OnboardingStage.completed,
      );
      states.movies.setStarterDeckMovies([
        _movie(id: 'ready-$count', movieRate: MovieRate.notRated),
      ]);

      await _pumpWizard(
        tester,
        states,
        mode: RatingFlowMode.continuous,
      );

      expect(find.text('Movie ready-$count'), findsOneWidget);
      expect(find.text('Taste profile ready'), findsNothing);
      expect(states.user.onboardingStage, OnboardingStage.completed);

      await tester.pumpWidget(const SizedBox.shrink());
      states.movies.dispose();
    }
  });

  testWidgets('continuous exhausted state is truthful and escapable',
      (tester) async {
    final states = await _statesWithRatings(
      200,
      onboardingStage: OnboardingStage.completed,
    );
    addTearDown(states.movies.dispose);
    states.movies.markStarterDeckRequestFinished();
    states.movies.markMoviesListsRequestFinished();

    await _pumpWizard(
      tester,
      states,
      mode: RatingFlowMode.continuous,
    );

    expect(find.text('No unrated picks ready'), findsOneWidget);
    expect(find.text('Retry unrated picks'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Popular Movies'), findsOneWidget);
    expect(find.text('Popular TV'), findsOneWidget);
    expect(find.text('Done for now'), findsOneWidget);
    expect(find.text('Taste profile ready'), findsNothing);
    expect(states.user.onboardingStage, OnboardingStage.completed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('continuous UI stays lightweight on medium and large phones',
      (tester) async {
    final states = await _statesWithRatings(
      50,
      onboardingStage: OnboardingStage.completed,
    );
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    states.movies.setStarterDeckMovies([
      _movie(
        id: 'responsive-continuous',
        movieRate: MovieRate.notRated,
        overview: List.filled(
          4,
          'A useful synopsis remains readable while optional rating controls stay within reach.',
        ).join(' '),
      ),
    ]);

    for (final size in const [Size(390, 844), Size(430, 932)]) {
      for (final scale in const [1.0, 1.3]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(size);
        await _pumpWizard(
          tester,
          states,
          mode: RatingFlowMode.continuous,
          textScale: scale,
          viewportSize: size,
        );

        expect(find.text('Rate more'), findsOneWidget);
        expect(find.byTooltip('Skip this title'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        expect(find.text('0 rated this session'), findsOneWidget);
        expect(find.byKey(const Key('rating-action-tray')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
      'process recreation excludes rated movies from a fresh starter deck',
      (tester) async {
    final states = await _statesWithRatings(1);
    addTearDown(states.movies.dispose);
    states.movies.setStarterDeckMovies([
      _movie(id: 'rated-0', movieRate: MovieRate.notRated),
      _movie(id: 'fresh-candidate', movieRate: MovieRate.notRated),
    ]);

    await _pumpWizard(tester, states);

    expect(find.text('1 of 10 movies rated'), findsOneWidget);
    expect(find.text('Movie rated-0'), findsNothing);
    expect(find.text('Movie fresh-candidate'), findsOneWidget);
  });

  testWidgets(
      'rating layout stays reachable across target sizes and text scales',
      (tester) async {
    final states = await _statesWithRatings(0);
    addTearDown(states.movies.dispose);
    states.movies.setStarterDeckMovies([
      _movie(
        id: 'compact-candidate',
        movieRate: MovieRate.notRated,
        overview: List.filled(
          6,
          'A long synopsis that should remain fully reachable while enlarged '
          'text and the sticky rating actions share a compact viewport.',
        ).join(' '),
      ),
    ]);

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
        await _pumpWizard(
          tester,
          states,
          textScale: scale,
          viewportSize: size,
        );

        expect(find.text('More'), findsOneWidget);
        expect(find.text('Liked'), findsOneWidget);
        expect(find.text('Okay'), findsOneWidget);
        expect(find.text('Disliked'), findsOneWidget);
        expect(find.text("Haven't seen it"), findsOneWidget);
        final sourceLabel = tester.renderObject<RenderParagraph>(
          find.byKey(const Key('starter-source-label')),
        );
        expect(sourceLabel.didExceedMaxLines, isFalse);
        expect(
          tester.getRect(find.text("Haven't seen it")).bottom,
          lessThan(size.height),
        );
        for (final label in const [
          'Liked',
          'Okay',
          'Disliked',
          "Haven't seen it",
        ]) {
          final labelWidget = tester.widget<Text>(find.text(label));
          expect(labelWidget.maxLines, 1);
        }

        final likedTarget = find.ancestor(
          of: find.text('Liked'),
          matching: find.byType(FilledButton),
        );
        final unseenTarget = find.ancestor(
          of: find.text("Haven't seen it"),
          matching: find.byType(TextButton),
        );
        expect(tester.getSize(likedTarget).height, greaterThanOrEqualTo(44));
        expect(tester.getSize(unseenTarget).height, greaterThanOrEqualTo(44));

        if (size.width <= 390 && scale >= 1.3) {
          final trayContext =
              tester.element(find.byKey(const Key('rating-action-tray')));
          expect(
            tester.getSize(find.byKey(const Key('rating-action-tray'))).height,
            greaterThanOrEqualTo(156),
            reason: 'Expected wrapped actions at $size and ${scale}x text; '
                'tray MediaQuery=${MediaQuery.sizeOf(trayContext)} / '
                '${MediaQuery.textScalerOf(trayContext).scale(1)}x.',
          );
        }

        await tester.ensureVisible(find.text('More'));
        await tester.pump();
        await tester.tap(find.text('More'));
        await tester.pumpAndSettle();
        expect(find.text('Less'), findsOneWidget);

        final scrollable =
            tester.state<ScrollableState>(find.byType(Scrollable).first);
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pump();

        final footerRect =
            tester.getRect(find.byKey(const Key('rating-later-footer')));
        final trayRect =
            tester.getRect(find.byKey(const Key('rating-action-tray')));
        expect(footerRect.bottom, lessThanOrEqualTo(trayRect.top));
        expect(footerRect.top, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('large-text Rate Movies visual goldens keep content clear',
      (tester) async {
    final states = await _statesWithRatings(0);
    addTearDown(states.movies.dispose);
    states.movies.setStarterDeckMovies([
      _movie(
        id: 'golden-candidate',
        movieRate: MovieRate.notRated,
        overview: List.filled(
          5,
          'MovieDiary keeps this synopsis reachable above every rating action.',
        ).join(' '),
      ),
    ]);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final scale in const [1.3, 2.0]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await _pumpWizard(
        tester,
        states,
        textScale: scale,
        viewportSize: const Size(360, 640),
      );
      await tester.ensureVisible(find.text('More'));
      await tester.pump();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('rating-later-footer')),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('onboarding-golden')),
        matchesGoldenFile(
          'goldens/uxr18-rate-360x640-${scale == 1.3 ? '1.3x' : '2x'}.png',
        ),
      );
    }
  });

  testWidgets('next candidate resets the content scroll position',
      (tester) async {
    final states = await _statesWithRatings(0);
    addTearDown(states.movies.dispose);
    states.movies.setStarterDeckMovies([
      _movie(
        id: 'candidate-a',
        movieRate: MovieRate.notRated,
        overview: List.filled(8, 'First candidate synopsis.').join(' '),
      ),
      _movie(
        id: 'candidate-b',
        movieRate: MovieRate.notRated,
        overview: 'Second candidate synopsis.',
      ),
    ]);

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpWizard(
      tester,
      states,
      viewportSize: const Size(360, 640),
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -260),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, greaterThan(0));

    await tester.tap(find.text("Haven't seen it"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Movie candidate-b'), findsOneWidget);
    expect(scrollable.position.pixels, 0);
    expect(find.text('More'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<_TestStates> _statesWithRatings(
  int count, {
  String onboardingStage = OnboardingStage.rating,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'guest-access',
    'refreshToken': 'guest-refresh',
    'userId': 'guest-onboarding-test',
    'isIncognitoMode': 'true',
    'onboardingStage': onboardingStage,
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  await user.setOnboardingStage(onboardingStage);
  final movies = MoviesState(storage: storage);
  await movies.cacheInitialization;
  movies.setInitialUserMovies([
    for (var index = 0; index < count; index++)
      _movie(id: 'rated-$index', movieRate: MovieRate.liked),
  ]);

  return _TestStates(storage: storage, user: user, movies: movies);
}

Future<void> _pumpWizard(
  WidgetTester tester,
  _TestStates states, {
  VoidCallback? onFinished,
  VoidCallback? onExitStarted,
  VoidCallback? onExitCompleted,
  WidgetBuilder? recommendationsBuilder,
  RatingFlowMode mode = RatingFlowMode.onboarding,
  double textScale = 1,
  Size? viewportSize,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserState>.value(value: states.user),
        ChangeNotifierProvider<MoviesState>.value(value: states.movies),
      ],
      child: MaterialApp(
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
          key: const Key('onboarding-golden'),
          child: OnboardingWizardPage(
            mode: mode,
            onFinished: onFinished ?? () {},
            onExitStarted: onExitStarted,
            onExitCompleted: onExitCompleted,
            recommendationsBuilder: recommendationsBuilder,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Movie _movie({
  required String id,
  required int movieRate,
  String overview = 'A trusted starter movie with a useful synopsis.',
}) {
  return Movie(
    id: id,
    title: 'Movie $id',
    overview: overview,
    tagline: null,
    posterPath: '/poster.jpg',
    duration: 112,
    rating: 82,
    allVotes: 100,
    likedVotes: 82,
    dislikedVotes: 18,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Drama', 'Adventure'],
    movieRate: movieRate,
    movieType: MovieType.movie,
    releaseDate: DateTime(2020),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8.1,
    imdbVotes: 10000,
  );
}

class _TestStates {
  final FlutterSecureStorage storage;
  final UserState user;
  final MoviesState movies;

  const _TestStates({
    required this.storage,
    required this.user,
    required this.movies,
  });
}
