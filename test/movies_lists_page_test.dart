import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/movies_lists_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'General intro is compact, dismisses per profile, and Personal has one empty action',
    (tester) async {
      final states = await _testStates(const []);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await _pumpLists(
        tester,
        states,
        pageKey: const ValueKey('lists-first-mount'),
      );
      expect(tester.takeException(), isNull);

      expect(find.byKey(const Key('lists-page-title')), findsOneWidget);
      expect(find.byKey(const Key('lists-segmented-bar')), findsOneWidget);
      expect(find.byIcon(Icons.public_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmarks_rounded), findsOneWidget);
      expect(find.byKey(const Key('general-intro')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('general-intro'))).height,
        lessThanOrEqualTo(176),
      );
      expect(find.text('Curated collections'), findsOneWidget);
      expect(
        find.text('Explore staff picks, classics, and popular themes.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Dismiss introduction'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('general-intro')), findsNothing);

      const storage = FlutterSecureStorage();
      expect(
        await storage.read(
          key: 'movieListsGeneralGuidanceDismissed.guest-lists-widget-test',
        ),
        'true',
      );

      await _pumpLists(
        tester,
        states,
        pageKey: const ValueKey('lists-second-mount'),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('general-intro')), findsNothing);

      await tester.tap(find.byKey(const Key('lists-tab-personal')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const Key('personal-lists-empty-state')), findsOneWidget);
      expect(find.text('Create your first personal list'), findsOneWidget);
      expect(
        find.text(
          'Group movies for a trip, mood, marathon, or anything else.',
        ),
        findsOneWidget,
      );
      expect(
          find.byKey(const Key('personal-empty-create-list')), findsOneWidget);
      expect(find.byKey(const Key('personal-lists-add-fab')), findsNothing);
      expect(find.text('Create List'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pumpLists(
        tester,
        states,
        pageKey: const ValueKey('lists-text-scale-two'),
        textScale: 2,
      );
      await tester.tap(find.byKey(const Key('lists-tab-personal')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('personal-lists-empty-state')), findsOneWidget);
      expect(tester.takeException(), isNull);

      const responsiveSizes = [
        Size(360, 640),
        Size(430, 932),
        Size(800, 1024),
      ];
      for (final size in responsiveSizes) {
        await tester.binding.setSurfaceSize(size);
        await _pumpLists(
          tester,
          states,
          pageKey: ValueKey('lists-${size.width.toInt()}'),
        );
        await tester.tap(find.byKey(const Key('lists-tab-personal')));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const Key('lists-segmented-bar'))).height,
          56,
        );
        expect(
          find.byKey(const Key('personal-lists-empty-state')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'list covers use zero, one, two, and three-image geometry without empty tiles',
    (tester) async {
      final lists = [
        _list('Zero', const []),
        _list('One', [
          _movie('one-a', posterPath: '/one-a.jpg'),
          _movie('one-empty'),
        ]),
        _list('Two', [
          _movie('two-a', posterPath: '/two-a.jpg'),
          _movie('two-b', posterPath: '/two-b.jpg'),
        ]),
        _list('Three', [
          _movie('three-a', posterPath: '/three-a.jpg'),
          _movie('three-b', posterPath: '/three-b.jpg'),
          _movie('three-c', posterPath: '/three-c.jpg'),
        ]),
      ];
      final states = await _testStates(
        lists,
        generalIntroDismissed: true,
      );
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await _pumpLists(tester, states);

      expect(
        tester.getSize(find.byKey(const Key('list-cover-Zero'))),
        const Size(84, 96),
      );
      expect(find.byKey(const Key('list-cover-Zero-fallback')), findsOneWidget);
      expect(find.byKey(const Key('list-cover-One-tile-0')), findsOneWidget);
      expect(find.byKey(const Key('list-cover-One-tile-1')), findsNothing);
      expect(find.byKey(const Key('list-cover-One-fallback')), findsNothing);
      expect(find.byKey(const Key('list-cover-Two-tile-0')), findsOneWidget);
      expect(find.byKey(const Key('list-cover-Two-tile-1')), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('list-card-external-Three')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.byKey(const Key('list-cover-Three-tile-0')), findsOneWidget);
      expect(find.byKey(const Key('list-cover-Three-tile-1')), findsOneWidget);
      expect(find.byKey(const Key('list-cover-Three-tile-2')), findsOneWidget);
      expect(find.byKey(const Key('list-cover-Three-fallback')), findsNothing);
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'create sheet disables duplicates and preserves the name for offline Retry',
    (tester) async {
      final service = _CreateListService(statusCode: 503);
      final states = await _testStates([
        _list(
          'Favorites',
          const [],
          type: MovieListType.personal,
        ),
      ]);
      addTearDown(states.movies.dispose);
      addTearDown(states.user.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await _pumpLists(
        tester,
        states,
        serviceAgent: service,
        textScale: 2,
        keyboardInset: 180,
      );

      await tester.tap(find.byKey(const Key('lists-tab-personal')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('personal-lists-add-fab')), findsOneWidget);
      expect(find.byKey(const Key('personal-empty-create-list')), findsNothing);

      await tester.tap(find.byKey(const Key('personal-lists-add-fab')));
      await tester.pumpAndSettle();
      expect(find.text('Create personal list'), findsOneWidget);
      expect(find.byKey(const Key('create-list-name-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('create-list-name-field')),
        ' Favorites ',
      );
      await tester.pump();
      expect(
        find.text('A list with this name already exists.'),
        findsOneWidget,
      );
      final duplicateButton = tester.widget<Md3PrimaryButton>(
        find.byKey(const Key('create-list-submit')),
      );
      expect(duplicateButton.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('create-list-name-field')),
        'Road Trip',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('create-list-submit')));
      await tester.tap(find.byKey(const Key('create-list-submit')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('create-list-request-error')), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('create-list-name-field')),
      );
      expect(field.controller?.text, 'Road Trip');
      expect(
        states.movies.personalMoviesLists
            .where((list) => list.name == 'Road Trip'),
        isEmpty,
      );

      service.statusCode = 201;
      await tester.ensureVisible(find.byKey(const Key('create-list-submit')));
      await tester.tap(find.byKey(const Key('create-list-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Create personal list'), findsNothing);
      expect(find.text('Created Road Trip'), findsOneWidget);
      expect(service.calls, 2);
      expect(
        states.movies.personalMoviesLists
            .where((list) => list.name == 'Road Trip')
            .length,
        1,
      );

      await _pumpLists(
        tester,
        states,
        pageKey: const ValueKey('lists-after-create'),
      );
      await tester.tap(find.byKey(const Key('lists-tab-personal')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('list-card-personal-Road Trip')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Road Trip'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<_TestStates> _testStates(
  List<MoviesList> lists, {
  bool generalIntroDismissed = false,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'guest-access',
    'refreshToken': 'guest-refresh',
    'userId': 'guest-lists-widget-test',
    'isIncognitoMode': 'true',
    if (generalIntroDismissed)
      'movieListsGeneralGuidanceDismissed.guest-lists-widget-test': 'true',
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  final movies = MoviesState(storage: storage);
  await movies.cacheInitialization;
  await movies.setInitialMoviesLists(lists);
  return _TestStates(user: user, movies: movies);
}

Future<void> _pumpLists(
  WidgetTester tester,
  _TestStates states, {
  Key? pageKey,
  ServiceAgent? serviceAgent,
  double textScale = 1,
  double keyboardInset = 0,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserState>.value(value: states.user),
        ChangeNotifierProvider<MoviesState>.value(value: states.movies),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: child!,
        ),
        home: MoviesListsPage(
          key: pageKey,
          initialPageIndex: 0,
          serviceAgent: serviceAgent,
          storage: const FlutterSecureStorage(),
        ),
      ),
    ),
    duration: const Duration(milliseconds: 20),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 220));
}

MoviesList _list(
  String name,
  List<Movie> movies, {
  MovieListType type = MovieListType.external,
}) {
  return MoviesList(
    name: name,
    order: name.hashCode,
    listMovies: movies,
    movieListType: type,
  );
}

Movie _movie(
  String id, {
  String posterPath = '',
}) {
  return Movie(
    id: id,
    title: 'Movie $id',
    overview: 'A useful movie synopsis.',
    tagline: null,
    posterPath: posterPath,
    duration: 110,
    rating: 80,
    allVotes: 100,
    likedVotes: 80,
    dislikedVotes: 20,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Drama'],
    movieRate: MovieRate.notRated,
    movieType: MovieType.movie,
    releaseDate: DateTime(2024),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8,
    imdbVotes: 1000,
  );
}

class _CreateListService extends ServiceAgent {
  int statusCode;
  int calls = 0;

  _CreateListService({required this.statusCode});

  @override
  Future<http.Response> createUserMoviesList(
    String userId,
    String listName,
    int order,
  ) async {
    calls += 1;
    return http.Response('', statusCode);
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
