import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/movie_status_control.dart';
import 'package:mmobile/Widgets/mark_watched_bottom_sheet.dart';
import 'package:mmobile/Widgets/movie_list_item.dart';
import 'package:mmobile/Widgets/movies_list_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('movie row system has no overflow across the target matrix', (
    tester,
  ) async {
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const sizes = [Size(390, 844), Size(430, 930)];
    const scales = [1.0, 1.2];
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
          expect(find.byType(MovieStatusControl), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: '${configuration.$1} at $size / text scale $scale',
          );
        }
      }
    }
  });

  testWidgets('row action target opens one independent scroll-safe sheet', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final observer = _CountingNavigatorObserver();

    await _pumpRow(
      tester,
      states,
      movieId: 'browse',
      mode: MovieCardMode.browse,
      textScale: 1.2,
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
    expect(find.bySemanticsLabel(RegExp(r'Movie actions\.')), findsOneWidget);

    await tester.tap(find.byType(MovieStatusControl).first);
    await tester.pumpAndSettle();

    expect(observer.pushCount, pushesBeforeAction + 1);
    expect(find.text('Movie actions'), findsOneWidget);
    expect(find.text('Add to Watchlist'), findsNothing);
    expect(find.text('Rate now'), findsNothing);
    expect(find.text('Create a personal list'), findsOneWidget);
    expect(find.text('Open details'), findsNothing);
    expect(find.byType(Md3BottomSheetSurface), findsOneWidget);
    expect(tester.takeException(), isNull);
    semanticsHandle.dispose();
  });

  testWidgets('all canonical states keep exact card and control geometry', (
    tester,
  ) async {
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = states.movies.userMovies.firstWhere(
      (m) => m.id == 'browse',
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(430, 930)]) {
      for (final scale in [1.0, 1.2]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        await tester.binding.setSurfaceSize(size);
        await tester.pump();
        double? height;
        Rect? rail;
        for (final rate in [
          MovieRate.notRated,
          MovieRate.addedToWatchlist,
          MovieRate.liked,
          MovieRate.okay,
          MovieRate.notLiked,
        ]) {
          fixture.movieRate = rate;
          await _pumpRow(
            tester,
            states,
            movieId: 'browse',
            mode: MovieCardMode.browse,
            textScale: scale,
          );
          final card = tester.getSize(
            find.byKey(const Key('movie-card-surface-browse')),
          );
          final action = tester.getRect(
            find.byKey(const Key('movie-card-trailing-action-browse')),
          );
          height ??= card.height;
          rail ??= action;
          expect(card.height, height);
          expect(action, rail);
          expect(action.size, const Size(44, 44));
          expect(
            find.byIcon(MovieStatusPresentation.forRate(rate).icon),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
          expect(find.byType(Md3OpinionBadge), findsNothing);
          final poster = tester.widget<Md3MoviePoster>(
            find.byType(Md3MoviePoster),
          );
          expect(poster.width, size.width <= 390 ? 72 : 80);
          expect(poster.height, poster.width * 1.5);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets(
    'inline status is single-submit with exact Undo and failure retry',
    (tester) async {
      final states = await _testStates();
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pumpRow(
        tester,
        states,
        movieId: 'browse',
        mode: MovieCardMode.browse,
        textScale: 1.2,
      );
      final movie = states.movies.userMovies.firstWhere(
        (m) => m.id == 'browse',
      );
      final revision = states.movies.movieMutationRevision(movie.id);
      await tester.tap(find.byType(MovieStatusControl));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('movie-status-watchlist')));
      await tester.tap(find.byKey(const Key('movie-status-watchlist')));
      await tester.pumpAndSettle();
      expect(movie.movieRate, MovieRate.addedToWatchlist);
      expect(states.movies.movieMutationRevision(movie.id), revision + 1);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(movie.movieRate, MovieRate.notRated);
      expect(states.movies.movieMutationRevision(movie.id), revision + 2);
      final oldService = ServiceAgent.state;
      states.user.isIncognitoMode = false;
      ServiceAgent.state = null;
      await tester.tap(find.byType(MovieStatusControl));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('movie-status-liked')));
      await tester.pumpAndSettle();
      expect(movie.movieRate, MovieRate.notRated);
      expect(find.textContaining('Couldn’t update'), findsOneWidget);
      expect(states.movies.isMovieMutationActive(movie.id), isFalse);
      states.user.isIncognitoMode = true;
      ServiceAgent.state = oldService;
      await tester.tap(find.byKey(const Key('movie-status-okay')));
      await tester.pumpAndSettle();
      expect(movie.movieRate, MovieRate.okay);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      states.movies.dispose();
    },
  );

  testWidgets(
    'selected inline state is accessible and repeated selection is safe',
    (tester) async {
      final states = await _testStates();
      final handle = tester.ensureSemantics();
      addTearDown(states.movies.dispose);

      await _pumpRow(
        tester,
        states,
        movieId: 'viewed',
        mode: MovieCardMode.viewed,
        textScale: 1,
      );
      await tester.tap(find.byType(MovieStatusControl));
      await tester.pumpAndSettle();
      final revision = states.movies.movieMutationRevision('viewed');
      expect(
        tester
            .widget<Semantics>(find.byKey(const Key('movie-status-liked')))
            .properties
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('movie-status-liked')));
      await tester.pumpAndSettle();
      expect(states.movies.movieMutationRevision('viewed'), revision);
      expect(find.text('Movie actions'), findsOneWidget);
      expect(find.text('Remove from Viewed'), findsOneWidget);
      handle.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'complete visible row surface opens details once and exposes one label',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      final states = await _testStates();
      addTearDown(states.movies.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final observer = _CountingNavigatorObserver();

      await _pumpRow(
        tester,
        states,
        movieId: 'browse',
        mode: MovieCardMode.browse,
        textScale: 1,
        observer: observer,
      );
      final initialPushes = observer.pushCount;
      final surface = find.byKey(const Key('movie-card-surface-browse'));
      expect(
        find.bySemanticsLabel(
          'Open A deliberately long translated movie title for layout testing '
          'details',
        ),
        findsOneWidget,
      );

      var rect = tester.getRect(surface);
      await tester.tapAt(Offset(rect.center.dx, rect.top + 3));
      await tester.pumpAndSettle();
      expect(observer.pushCount, initialPushes + 1);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      rect = tester.getRect(surface);
      await tester.tapAt(rect.bottomCenter - const Offset(0, 3));
      await tester.pumpAndSettle();
      expect(observer.pushCount, initialPushes + 2);
      expect(tester.takeException(), isNull);
      semanticsHandle.dispose();
    },
  );

  testWidgets(
    'watchlist action is compact with one adaptive trailing control',
    (tester) async {
      final states = await _testStates();
      addTearDown(states.movies.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final configuration in const [
        (Size(390, 844), 1.0, 'watchlist'),
        (Size(430, 930), 1.0, 'watchlist'),
        (Size(390, 844), 1.2, 'watchlist-long-tv'),
        (Size(430, 930), 1.2, 'watchlist-missing'),
      ]) {
        await tester.binding.setSurfaceSize(configuration.$1);
        await _pumpRow(
          tester,
          states,
          movieId: configuration.$3,
          mode: MovieCardMode.watchlist,
          textScale: configuration.$2,
        );

        final movie = states.movies.userMovies.firstWhere(
          (movie) => movie.id == configuration.$3,
        );
        final titleLeft = tester.getTopLeft(find.text(movie.title)).dx;
        final action = find.byKey(const Key('movie-card-mark-watched-action'));
        final actionSize = tester.getSize(action);
        final rowCard = find.byKey(
          ValueKey('movie-card-surface-${configuration.$3}'),
        );
        final trailing = find.byKey(
          ValueKey('movie-card-trailing-action-${configuration.$3}'),
        );
        expect(tester.getTopLeft(action).dx, closeTo(titleLeft, 0.5));
        expect(actionSize.height, greaterThanOrEqualTo(Md3Targets.minimum));
        expect(
          actionSize.width,
          lessThan(tester.getSize(rowCard).width * 0.62),
        );
        expect(tester.getSize(trailing), const Size(44, 44));
        expect(
          tester.getSize(rowCard).height,
          configuration.$2 == 1 ? lessThan(180) : lessThan(250),
          reason: '${configuration.$1} at ${configuration.$2}x',
        );
        expect(find.text('Mark watched'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp(r'Movie actions\.')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        final button = tester.widget<FilledButton>(
          find.descendant(of: action, matching: find.byType(FilledButton)),
        );
        expect(
          button.style?.backgroundColor?.resolve({}),
          Md3Colors.primarySoft,
        );
        expect(button.style?.foregroundColor?.resolve({}), Md3Colors.primary);
      }
    },
  );

  testWidgets('watchlist nested actions do not open details', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final observer = _CountingNavigatorObserver();

    await _pumpRow(
      tester,
      states,
      movieId: 'watchlist',
      mode: MovieCardMode.watchlist,
      textScale: 1.2,
      observer: observer,
    );
    final pushesBeforeAction = observer.pushCount;
    expect(find.bySemanticsLabel('Mark watched'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Movie actions\.')), findsOneWidget);

    await tester.tap(find.text('Mark watched'));
    await tester.pumpAndSettle();
    expect(find.text('How was it?'), findsOneWidget);
    expect(find.byType(Md3BottomSheetSurface), findsOneWidget);
    expect(find.bySemanticsLabel('Open The Matrix details'), findsOneWidget);
    expect(observer.pushCount, pushesBeforeAction + 1);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      states.movies.userMovies
          .singleWhere((m) => m.id == 'watchlist')
          .movieRate,
      MovieRate.addedToWatchlist,
    );
    expect(find.byType(Md3BottomSheetSurface), findsNothing);
    expect(tester.takeException(), isNull);
    semanticsHandle.dispose();
  });

  testWidgets('row action sheet dismisses by scrim close back and drag', (
    tester,
  ) async {
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    Future<void> openActions() async {
      await _pumpRow(
        tester,
        states,
        movieId: 'browse',
        mode: MovieCardMode.browse,
        textScale: 1,
      );
      await tester.tap(find.byType(MovieStatusControl));
      await tester.pumpAndSettle();
      expect(find.byType(Md3BottomSheetSurface), findsOneWidget);
    }

    await openActions();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(Md3BottomSheetSurface), findsNothing);

    await openActions();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(Md3BottomSheetSurface), findsNothing);

    await openActions();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Md3BottomSheetSurface), findsNothing);

    await openActions();
    await tester.drag(
      find.byKey(const Key('md3-bottom-sheet-drag-handle')),
      const Offset(0, 96),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Md3BottomSheetSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search row Watchlist Undo restores state exactly once', (
    tester,
  ) async {
    final states = await _testStates();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await _pumpRow(
      tester,
      states,
      movieId: 'viewed',
      mode: MovieCardMode.browse,
      textScale: 1,
    );
    await tester.tap(find.byType(MovieStatusControl));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movie-status-watchlist')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movieDiaryDialogConfirmLabel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final movie = states.movies.userMovies.firstWhere(
      (movie) => movie.id == 'viewed',
    );
    expect(movie.movieRate, MovieRate.addedToWatchlist);
    expect(find.text('Moved to Watchlist · Rating removed'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(movie.movieRate, MovieRate.liked);
    expect(
      find.text('Undo complete · Previous status restored'),
      findsOneWidget,
    );
    expect(find.text('Undo'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    states.movies.dispose();
  });

  testWidgets('browse row adds directly to an existing personal list', (
    tester,
  ) async {
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
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await _pumpRow(
      tester,
      states,
      movieId: 'browse',
      mode: MovieCardMode.browse,
      textScale: 1,
    );

    await tester.tap(find.byType(MovieStatusControl));
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
      states.movies.personalMoviesLists.single.listMovies.map(
        (movie) => movie.id,
      ),
      contains('browse'),
    );
    expect(find.text('Added to Weekend Picks.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('restored personal membership uses IDs and preserves status', (
    tester,
  ) async {
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    final canonical = states.movies.userMovies.firstWhere(
      (movie) => movie.id == 'personal',
    );
    final restored = _movie(
      id: canonical.id,
      title: canonical.title,
      movieRate: canonical.movieRate,
    );
    await states.movies.setInitialMoviesLists([
      MoviesList(
        name: 'Weekend Picks',
        order: 1,
        listMovies: [restored],
        movieListType: MovieListType.personal,
      ),
    ]);
    states.movies.addMovieToPersonalList('Weekend Picks', canonical);
    expect(states.movies.personalMoviesLists.single.listMovies, hasLength(1));
    await tester.pumpWidget(
      _app(
        states,
        textScale: 1,
        home: MoviesListPage(
          moviesList: states.movies.personalMoviesLists.single,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MovieListItem), findsOneWidget);
    states.movies.removeMovieFromPersonalList('Weekend Picks', canonical);
    await tester.pumpAndSettle();
    expect(states.movies.personalMoviesLists.single.listMovies, isEmpty);
    expect(find.text('This list is empty'), findsOneWidget);
    expect(find.byType(MovieListItem), findsNothing);
    expect(canonical.movieRate, MovieRate.okay);
    expect(states.movies.userMovies, contains(canonical));
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('inline selector preserves every canonical lifecycle transition', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    for (final transition in const [
      (MovieRate.notRated, MovieRate.liked),
      (MovieRate.notRated, MovieRate.okay),
      (MovieRate.notRated, MovieRate.notLiked),
      (MovieRate.notRated, MovieRate.addedToWatchlist),
      (MovieRate.addedToWatchlist, MovieRate.liked),
      (MovieRate.addedToWatchlist, MovieRate.okay),
      (MovieRate.addedToWatchlist, MovieRate.notLiked),
      (MovieRate.liked, MovieRate.okay),
      (MovieRate.okay, MovieRate.notLiked),
      (MovieRate.notLiked, MovieRate.addedToWatchlist),
    ]) {
      final states = await _testStates();
      final fixture = states.movies.userMovies.firstWhere(
        (m) => m.id == 'browse',
      );
      if (transition.$1 != MovieRate.notRated) {
        await states.movies.changeMovieRate(
          fixture.id,
          transition.$1,
          true,
          fixture,
        );
      }
      await _pumpRow(
        tester,
        states,
        movieId: 'browse',
        mode: MovieCardMode.browse,
        textScale: 1.2,
      );
      await tester.tap(find.byType(MovieStatusControl));
      await tester.pumpAndSettle();
      for (final rate in [
        MovieRate.liked,
        MovieRate.okay,
        MovieRate.notLiked,
        MovieRate.addedToWatchlist,
      ]) {
        final key = ValueKey(
          'movie-status-${MovieRate.opinionLabel(rate).toLowerCase()}',
        );
        expect(
          tester.widget<Semantics>(find.byKey(key)).properties.selected,
          rate == transition.$1,
        );
      }
      await tester.tap(
        find.byKey(
          ValueKey(
            'movie-status-${MovieRate.opinionLabel(transition.$2).toLowerCase()}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (MovieRate.isViewed(transition.$1) &&
          transition.$2 == MovieRate.addedToWatchlist) {
        expect(find.textContaining('rating will be removed'), findsOneWidget);
        await tester.tap(find.byKey(const Key('movieDiaryDialogConfirmLabel')));
        await tester.pumpAndSettle();
      }
      expect(fixture.movieRate, transition.$2);
      expect(
        states.movies.userMovies.where((m) => m.id == fixture.id),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      states.movies.dispose();
    }
  });

  testWidgets('Mark Watched presenter keeps every action scroll reachable', (
    tester,
  ) async {
    final states = await _testStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final movie = states.movies.userMovies.firstWhere(
      (movie) => movie.movieRate == MovieRate.addedToWatchlist,
    );

    const sizes = [Size(390, 844), Size(430, 930)];
    const scales = [1.0, 1.2];

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
          tester.getRect(find.text('Cancel')).bottom,
          lessThan(size.height),
        );
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
      id: 'watchlist-long-tv',
      title: 'A deliberately long television title that needs two lines',
      movieRate: MovieRate.addedToWatchlist,
      movieType: MovieType.tv,
      duration: 0,
      seasonsCount: 12,
    ),
    _movie(
      id: 'watchlist-missing',
      title: 'Missing metadata',
      movieRate: MovieRate.addedToWatchlist,
      duration: 0,
      genres: const [],
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
            movie: states.movies.userMovies.firstWhere(
              (movie) => movie.id == movieId,
            ),
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
              onPressed: () =>
                  showMarkWatchedBottomSheet(context: context, movie: movie),
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
      navigatorObservers: [if (observer != null) observer],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
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
  MovieType movieType = MovieType.movie,
  int duration = 136,
  int seasonsCount = 0,
  List<String> genres = const ['Action', 'Science Fiction', 'Adventure'],
}) {
  return Movie(
    id: id,
    title: title,
    overview: 'A useful movie synopsis.',
    tagline: null,
    posterPath: '',
    duration: duration,
    rating: 85,
    allVotes: 100,
    likedVotes: 85,
    dislikedVotes: 15,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: genres,
    movieRate: movieRate,
    movieType: movieType,
    releaseDate: DateTime(1999),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: seasonsCount,
    imdbRate: 8.7,
    imdbVotes: 100000,
  );
}

class _TestStates {
  final UserState user;
  final MoviesState movies;

  const _TestStates({required this.user, required this.movies});
}

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    super.didPush(route, previousRoute);
  }
}
