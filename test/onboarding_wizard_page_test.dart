import 'package:flutter/material.dart';
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
      'rating layout stays reachable across target sizes and text scales',
      (tester) async {
    final states = await _statesWithRatings(0);
    addTearDown(states.movies.dispose);
    states.movies.setStarterDeckMovies([
      _movie(
        id: 'compact-candidate',
        movieRate: MovieRate.notRated,
        overview:
            'A long synopsis that should remain concise by default while the '
            'rating actions stay available as the primary repetitive task.',
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
        await tester.binding.setSurfaceSize(size);
        await _pumpWizard(tester, states, textScale: scale);

        expect(find.text('More'), findsOneWidget);
        expect(find.text('Liked'), findsOneWidget);
        expect(find.text('Okay'), findsOneWidget);
        expect(find.text('Disliked'), findsOneWidget);
        expect(find.text("Haven't seen it"), findsOneWidget);
        expect(
          tester.getRect(find.text("Haven't seen it")).bottom,
          lessThan(size.height),
        );
        expect(tester.takeException(), isNull);
      }
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
    await _pumpWizard(tester, states);

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

Future<_TestStates> _statesWithRatings(int count) async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'guest-access',
    'refreshToken': 'guest-refresh',
    'userId': 'guest-onboarding-test',
    'isIncognitoMode': 'true',
    'onboardingStage': OnboardingStage.rating,
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  await user.setOnboardingStage(OnboardingStage.rating);
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
  double textScale = 1,
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
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          );
        },
        home: OnboardingWizardPage(
          onFinished: onFinished ?? () {},
          onExitStarted: onExitStarted,
          onExitCompleted: onExitCompleted,
          recommendationsBuilder: recommendationsBuilder,
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
