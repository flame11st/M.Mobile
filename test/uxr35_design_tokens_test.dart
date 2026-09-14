import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/movies_bottom_navigation_bar.dart';

void main() {
  test('UXR35 exposes the documented semantic design contract', () {
    expect(
      const [
        Md3Spacing.x4,
        Md3Spacing.x8,
        Md3Spacing.x12,
        Md3Spacing.x16,
        Md3Spacing.x20,
        Md3Spacing.x24,
        Md3Spacing.x32,
        Md3Spacing.x40,
        Md3Spacing.x48,
      ],
      const [4, 8, 12, 16, 20, 24, 32, 40, 48],
    );
    expect(Md3Spacing.screen, 24);
    expect(Md3Spacing.card, inInclusiveRange(20, 24));
    expect(Md3Radius.button, 20);
    expect(Md3Radius.card, 24);
    expect(Md3Radius.sheet, 32);
    expect(Md3Radius.poster, 16);
    expect(Md3Radius.navigation, 28);
    expect(Md3NavigationMetrics.dockHeight, 64);
    expect(Md3NavigationMetrics.horizontalMargin, inInclusiveRange(20, 24));
    expect(Md3NavigationMetrics.itemMinimumHeight, 56);
    expect(Md3NavigationMetrics.iconSize, inInclusiveRange(24, 26));
    expect(Md3NavigationMetrics.labelSize, inInclusiveRange(13, 14));
    expect(Md3Durations.feedback, const Duration(milliseconds: 160));
    expect(Md3Durations.standard, const Duration(milliseconds: 180));
  });

  test('opinion and destructive roles cannot collapse into one red', () {
    expect(Md3Colors.liked, isNot(Md3Colors.okay));
    expect(Md3Colors.okay, isNot(Md3Colors.disliked));
    expect(Md3Colors.disliked, isNot(Md3Colors.destructive));
    expect(Md3Colors.error, Md3Colors.destructive);
  });

  test('theme and shared component defaults consume semantic roles', () {
    final theme = MovieDiaryTheme.light();
    const card = Md3Card(child: SizedBox.shrink());
    const sheet = Md3BottomSheetSurface(child: SizedBox.shrink());
    final poster = Md3MoviePoster(
      movie: _movie(),
      width: 72,
      height: 108,
      hydrateMissingPoster: false,
    );

    expect(theme.colorScheme.error, Md3Colors.error);
    expect(
      theme.textTheme.displayLarge?.fontSize,
      Md3Typography.pageTitle.fontSize,
    );
    expect(
      theme.textTheme.headlineMedium?.fontSize,
      Md3Typography.sectionTitle.fontSize,
    );
    expect(
      theme.textTheme.bodyLarge?.fontSize,
      Md3Typography.body.fontSize,
    );
    expect(card.padding, const EdgeInsets.all(Md3Spacing.card));
    expect(card.borderRadius, Md3Radius.card);
    expect(sheet.borderRadius, Md3Radius.sheet);
    expect(poster.borderRadius, Md3Radius.poster);
  });

  for (final configuration in <({Size size, double scale, double safeBottom})>[
    (size: const Size(390, 844), scale: 1, safeBottom: 24),
    (size: const Size(430, 930), scale: 1.3, safeBottom: 34),
  ]) {
    testWidgets(
      'bottom navigation keeps token geometry at '
      '${configuration.size.width.toInt()}x${configuration.size.height.toInt()} '
      '${configuration.scale}x',
      (tester) async {
        await tester.binding.setSurfaceSize(configuration.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: MovieDiaryTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: configuration.size,
                viewPadding: EdgeInsets.only(
                  bottom: configuration.safeBottom,
                ),
                textScaler: TextScaler.linear(configuration.scale),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: const SizedBox.expand(),
                bottomNavigationBar: MoviesBottomNavigationBar(
                  selectedIndex: 0,
                  onTabSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final glass = tester.widget<Md3LiquidGlass>(
          find.byType(Md3LiquidGlass),
        );
        expect(
          glass.borderRadius,
          BorderRadius.circular(Md3Radius.navigation),
        );
        expect(glass.tint, Md3Colors.glassTint);
        expect(glass.shadows, Md3Shadows.navigation);

        for (var index = 0; index < 5; index += 1) {
          final size = tester.getSize(
            find.byKey(ValueKey('root-navigation-item-$index')),
          );
          expect(size.width, greaterThanOrEqualTo(Md3Targets.minimum));
          expect(size.height, greaterThanOrEqualTo(Md3Targets.minimum));
        }

        final dock = tester.getSize(
          find.byKey(const ValueKey('root-navigation-dock')),
        );
        expect(dock.height, Md3NavigationMetrics.dockHeight);
        final safeArea = tester.getSize(
          find.byKey(const ValueKey('root-navigation-safe-area')),
        );
        expect(
          safeArea.height,
          Md3NavigationMetrics.visibleDockHeight + configuration.safeBottom,
        );
        final selectedPill = tester.getSize(
          find.byKey(const ValueKey('root-navigation-selection-0')),
        );
        expect(selectedPill.height, Md3NavigationMetrics.itemMinimumHeight);
        final selectedContainer = tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey('root-navigation-selection-0')),
        );
        expect(
          selectedContainer.padding,
          const EdgeInsets.symmetric(horizontal: 12),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('opaque content cards never inherit glass treatment',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MovieDiaryTheme.light(),
        home: const Scaffold(
          body: Md3Card(
            child: Text('Opaque content'),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    final decorated = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((decoration) => decoration.color == Md3Colors.surface);
    expect(decorated.borderRadius, BorderRadius.circular(Md3Radius.card));
    expect(decorated.boxShadow, Md3Shadows.contentCard);
  });

  testWidgets('primary button keeps a high-contrast foreground',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MovieDiaryTheme.light(),
        home: Scaffold(
          body: Md3PrimaryButton(
            text: 'Primary action',
            icon: Icons.check_rounded,
            onPressed: () {},
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Primary action'));
    expect(label.style?.color, Colors.white);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.check_rounded)).color,
      isNull,
    );
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.check_rounded))).color,
      Colors.white,
    );
  });
}

Movie _movie() {
  return Movie(
    id: 'uxr35-poster',
    title: 'MovieDiary',
    overview: '',
    tagline: null,
    posterPath: '',
    duration: 100,
    rating: 80,
    allVotes: 1,
    likedVotes: 1,
    dislikedVotes: 0,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Drama'],
    movieRate: MovieRate.notRated,
    movieType: MovieType.movie,
    releaseDate: DateTime(2026),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8,
    imdbVotes: 100,
  );
}
