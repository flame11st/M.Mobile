import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/discover_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Discover section actions stack without squeezing titles',
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
          var openListsCount = 0;
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await tester.binding.setSurfaceSize(size);
          await _pumpDiscover(
            tester,
            userState,
            moviesState,
            textScale: scale,
            viewportSize: size,
            onOpenLists: () => openListsCount++,
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
          await tester.pump();
          expect(openListsCount, 1);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('Discover compact large-text section visual golden',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final userState = UserState(storage: storage);
    await userState.initialization;
    final moviesState = MoviesState(storage: storage);
    await moviesState.cacheInitialization;
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
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('discover-section-title-Popular Movies'),
      ),
    );
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('discover-section-action-Popular Movies'),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('discover-golden')),
      matchesGoldenFile('goldens/uxr18-discover-360x640-2x.png'),
    );
  });

  testWidgets('ready taste state keeps the same large-text header geometry',
      (tester) async {
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
    expect(find.text('Your taste profile'), findsOneWidget);
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

  testWidgets(
    'taste profile stays consolidated below at and above readiness',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const scenarios = [
        (count: 9, size: Size(320, 568), textScale: 2.0),
        (count: 10, size: Size(360, 640), textScale: 1.0),
        (count: 11, size: Size(430, 932), textScale: 1.3),
      ];

      for (final scenario in scenarios) {
        FlutterSecureStorage.setMockInitialValues({});
        const storage = FlutterSecureStorage();
        final userState = UserState(storage: storage);
        await userState.initialization;
        final moviesState = MoviesState(storage: storage);
        await moviesState.cacheInitialization;
        moviesState.setInitialUserMovies([
          for (var index = 0; index < scenario.count; index++)
            _ratedMovie(index),
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
          ...find.text('Your taste profile').evaluate(),
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

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        moviesState.dispose();
      }
    },
  );

  testWidgets(
    'under-10 taste progress stacks before compact text fragments',
    (tester) async {
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

      final layoutFinder = find.byKey(
        const Key('taste-progress-action-layout'),
      );
      final progressLabelFinder = find.byKey(
        const Key('taste-progress-label'),
      );
      await tester.ensureVisible(layoutFinder);
      await tester.pump();

      expect(tester.widget(layoutFinder), isA<Column>());
      expect(
        tester.getSize(progressLabelFinder).width,
        greaterThan(180),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpDiscover(
  WidgetTester tester,
  UserState userState,
  MoviesState moviesState, {
  required double textScale,
  required Size viewportSize,
  required VoidCallback onOpenLists,
}) async {
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
          child: DiscoverPage(
            isOffline: true,
            onRetry: () async {},
            onOpenLists: onOpenLists,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
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
