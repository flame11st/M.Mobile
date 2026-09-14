import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/movie_community_signal.dart';
import 'package:mmobile/Widgets/movie_list_item.dart';
import 'package:provider/provider.dart';

import 'discover_movie_card_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final discover in [false, true]) {
    testWidgets('UXR97 visual ${discover ? 'Discover' : 'general'} tall card', (
      tester,
    ) async {
      final states = await fixtures.testStates();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final movie = fixtures.fixture()
        ..title = 'Spider-Man: Brand New Day Extended Edition'
        ..imdbRate = 7.8;
      await pumpCard(tester, states, movie, discover: discover, scale: 1.2);
      await expectLater(
        find.byKey(const Key('uxr97-frame')),
        matchesGoldenFile(
          'goldens/uxr97-after-${discover ? 'discover' : 'general'}-390-1.2x.png',
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      states.$1.dispose();
    });
  }

  testWidgets(
    'poster centers in all shared modes without centering text or resizing',
    (tester) async {
      final states = await fixtures.testStates();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [390.0, 430.0]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        for (final scale in [1.0, 1.2]) {
          for (final mode in MovieCardMode.values) {
            for (final discover in [false, true]) {
              final movie = fixtures.fixture()
                ..title = 'Spider-Man: Brand New Day Extended Edition'
                ..imdbRate = 7.8;
              Rect? firstCard;
              Rect? firstPoster;
              for (final rate in [
                MovieRate.notRated,
                MovieRate.addedToWatchlist,
                MovieRate.liked,
                MovieRate.okay,
                MovieRate.notLiked,
              ]) {
                movie.movieRate = rate;
                await pumpCard(
                  tester,
                  states,
                  movie,
                  mode: mode,
                  discover: discover,
                  scale: scale,
                );
                final card = tester.getRect(
                  find.byKey(
                    const ValueKey('movie-card-surface-discovery-fixture'),
                  ),
                );
                final poster = tester.getRect(find.byType(Md3MoviePoster));
                final title = tester.getRect(find.text(movie.title));
                expect(poster.center.dy, closeTo(card.center.dy, .01));
                expect(
                  poster.size,
                  width == 390 ? const Size(72, 108) : const Size(80, 120),
                );
                expect(title.top - card.top, closeTo(13, .01));
                final viewport = tester.widget<Md3MoviePoster>(
                  find.byType(Md3MoviePoster),
                );
                expect(viewport.borderRadius, Md3Radius.poster);
                firstCard ??= card;
                firstPoster ??= poster;
                expect(card, firstCard);
                expect(poster, firstPoster);
                expect(tester.takeException(), isNull);
              }
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      states.$1.dispose();
    },
  );

  testWidgets(
    'short content and missing-to-error poster preserve fixed centered viewport',
    (tester) async {
      final states = await fixtures.testStates();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final movie = fixtures.fixture()..title = 'Dune';
      await pumpCard(tester, states, movie);
      final initial = tester.getRect(find.byType(Md3MoviePoster));
      final initialCard = tester.getRect(
        find.byKey(const ValueKey('movie-card-surface-discovery-fixture')),
      );
      movie.posterPath = 'https://example.invalid/uxr97-poster.jpg';
      await pumpCard(tester, states, movie);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(find.byType(Md3MoviePoster)), initial);
      expect(
        tester.getRect(
          find.byKey(const ValueKey('movie-card-surface-discovery-fixture')),
        ),
        initialCard,
      );
      expect(initial.center.dy, closeTo(initialCard.center.dy, .01));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      states.$1.dispose();
    },
  );
}

Future<void> pumpCard(
  WidgetTester tester,
  (MoviesState, UserState) states,
  Movie movie, {
  MovieCardMode mode = MovieCardMode.browse,
  bool discover = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MoviesState>.value(value: states.$1),
        ChangeNotifierProvider<UserState>.value(value: states.$2),
      ],
      child: MaterialApp(
        theme: MovieDiaryTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('uxr97-frame'),
            child: SizedBox.expand(
              child: SingleChildScrollView(
                child: MovieListItem(
                  movie: movie,
                  mode: mode,
                  supplementaryContent: discover
                      ? MovieCommunitySignal.forMovie(movie)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
