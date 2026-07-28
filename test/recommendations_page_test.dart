import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/recommendation_discovery_session.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/recommendations_page.dart';
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
      'filters preserve the current deck and actions expose unmistakable state',
      (tester) async {
    final states = await _testStates();
    final service = _FakeRecommendationService(
      response: _session([_movie()]),
    );

    await _pumpRecommendations(
      tester,
      states,
      service: service,
      size: const Size(360, 640),
    );

    expect(find.byKey(const Key('recommendation-filter-bar')), findsOneWidget);
    expect(find.text('Start Discovery'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(const Key('recommendation-sticky-command-bar')),
          )
          .height,
      68,
    );

    await tester.tap(find.text('Start Discovery'));
    await tester.pumpAndSettle();

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('96% match'), findsOneWidget);
    expect(find.text('Add to Watchlist'), findsOneWidget);
    expect(find.text('Seen already'), findsOneWidget);
    expect(find.text('Open details'), findsOneWidget);
    expect(find.text('Refresh deck'), findsOneWidget);

    await tester.tap(find.text('TV'));
    await tester.pump();

    expect(find.text('Dune'), findsOneWidget);
    expect(find.textContaining('Your current deck stays'), findsOneWidget);
    expect(find.text('Build TV deck'), findsOneWidget);

    await tester.tap(find.byTooltip('Discovery style: Balanced'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adventurous').last);
    await tester.pumpAndSettle();

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Build TV deck'), findsOneWidget);

    await tester.drag(
      find.byType(ListView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seen already'));
    await tester.pumpAndSettle();
    expect(find.text('How was it?'), findsOneWidget);
    expect(find.text('Liked'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('Disliked'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    states.user.isIncognitoMode = false;
    await tester.tap(find.text('Add to Watchlist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('In Watchlist'), findsOneWidget);
    expect(
      states.movies.userMovies
          .singleWhere((movie) => movie.id == 'dune')
          .movieRate,
      MovieRate.addedToWatchlist,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('generation exposes cancel and truthful timeout recovery',
      (tester) async {
    final states = await _testStates();
    final service = _FakeRecommendationService(
      delay: const Duration(seconds: 2),
      response: _session([_movie()]),
    );

    await _pumpRecommendations(
      tester,
      states,
      service: service,
      generationTimeout: const Duration(milliseconds: 80),
    );

    await tester.tap(find.text('Start Discovery'));
    await tester.pump();

    expect(
        find.byKey(const Key('recommendation-loading-state')), findsOneWidget);
    expect(find.text('Building your deck'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      find.byKey(const Key('recommendation-sticky-command-bar')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('This deck took too long'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Back to Discover'), findsOneWidget);
    expect(find.text('Building your deck'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('cancel and empty deck remain distinct terminal states',
      (tester) async {
    final states = await _testStates();
    final slowService = _FakeRecommendationService(
      delay: const Duration(milliseconds: 200),
      response: _session([_movie()]),
    );

    await _pumpRecommendations(
      tester,
      states,
      service: slowService,
      generationTimeout: const Duration(seconds: 1),
    );

    await tester.tap(find.text('Start Discovery'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Discovery paused'), findsOneWidget);
    expect(find.text('Start Discovery'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    await _pumpRecommendations(
      tester,
      states,
      service: _FakeRecommendationService(response: _emptySession()),
    );
    await tester.tap(find.text('Start Discovery'));
    await tester.pumpAndSettle();

    expect(find.text('No recommendations in this deck yet.'), findsOneWidget);
    expect(find.text('Rate more movies'), findsOneWidget);
    expect(find.text('Use Adventurous'), findsOneWidget);
    expect(find.text('Try Adventurous'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result card remains reachable at 320x568 and text scale 2.0',
      (tester) async {
    final states = await _testStates();

    await _pumpRecommendations(
      tester,
      states,
      service: _FakeRecommendationService(
        response: _session([
          _movie(
            title:
                'A deliberately long recommendation title for compact phones',
          ),
        ]),
      ),
      size: const Size(320, 568),
      textScale: 2,
      autoStart: true,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recommendation-result-deck')), findsOneWidget);
    await tester.ensureVisible(find.text('Open details'));
    await tester.pumpAndSettle();

    final openDetailsBottom = tester.getRect(find.text('Open details')).bottom;
    expect(openDetailsBottom, lessThan(568));
    final compactBarHeight = tester
        .getSize(
          find.byKey(const Key('recommendation-sticky-command-bar')),
        )
        .height;
    expect(compactBarHeight, inInclusiveRange(52, 68));
    expect(tester.takeException(), isNull);
  });
}

Future<_TestStates> _testStates() async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'guest-access',
    'refreshToken': 'guest-refresh',
    'userId': 'guest-recommendations-test',
    'isIncognitoMode': 'true',
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  final movies = MoviesState(storage: storage);
  await movies.cacheInitialization;

  return _TestStates(user: user, movies: movies);
}

Future<void> _pumpRecommendations(
  WidgetTester tester,
  _TestStates states, {
  required ServiceAgent service,
  Size size = const Size(360, 640),
  double textScale = 1,
  Duration generationTimeout = const Duration(seconds: 1),
  bool autoStart = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
        home: RecommendationsPage(
          key: UniqueKey(),
          autoStart: autoStart,
          serviceAgent: service,
          generationTimeout: generationTimeout,
        ),
      ),
    ),
  );
  await tester.pump();
}

RecommendationDiscoverySession _session(List<Movie> movies) {
  return RecommendationDiscoverySession(
    sessionId: 'session-1',
    batchId: 'batch-1',
    movieType: MovieType.movie,
    discoveryLevel: RecommendationDiscoveryLevel.balanced,
    expiresAt: DateTime(2030),
    items: movies,
    nextCursor: movies.length,
    hasMore: false,
    pageSize: 10,
  );
}

RecommendationDiscoverySession _emptySession() {
  return RecommendationDiscoverySession(
    sessionId: '00000000-0000-0000-0000-000000000000',
    batchId: '00000000-0000-0000-0000-000000000000',
    movieType: MovieType.movie,
    discoveryLevel: RecommendationDiscoveryLevel.balanced,
    expiresAt: DateTime(2030),
    items: const [],
    nextCursor: 0,
    hasMore: false,
    pageSize: 10,
  );
}

Movie _movie({
  String title = 'Dune',
}) {
  return Movie(
    id: 'dune',
    title: title,
    overview: 'A useful recommendation synopsis.',
    tagline: null,
    posterPath: '',
    duration: 155,
    rating: 90,
    allVotes: 100,
    likedVotes: 90,
    dislikedVotes: 10,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Science Fiction', 'Adventure'],
    movieRate: MovieRate.notRated,
    movieType: MovieType.movie,
    releaseDate: DateTime(2021),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8,
    imdbVotes: 1100000,
    recommendationMatchPercent: 96,
    recommendationReason:
        'A strong fit for your science-fiction and adventure taste.',
  );
}

class _FakeRecommendationService extends ServiceAgent {
  final Duration delay;
  final RecommendationDiscoverySession? response;

  _FakeRecommendationService({
    required this.response,
    this.delay = Duration.zero,
  });

  @override
  Future<RecommendationDiscoverySession?> createDiscoverySession(
    String userId,
    MovieType movieType,
    RecommendationDiscoveryLevel discoveryLevel,
    int pageSize,
  ) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return response;
  }

  @override
  Future<http.Response> rateMovie(
    String movieId,
    String userId,
    int movieRate,
  ) async {
    return http.Response('', 200);
  }
}

class _TestStates {
  final UserState user;
  final MoviesState movies;

  const _TestStates({
    required this.user,
    required this.movies,
  });
}
