import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Helpers/movie_list_curator.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

void main() {
  test('MovieDiary theme uses the immutable UXR16 tokens', () {
    final theme = MovieDiaryTheme.light();

    expect(theme.scaffoldBackgroundColor, Md3Colors.background);
    expect(theme.colorScheme.primary, Md3Colors.primary);
    expect(theme.colorScheme.primaryContainer, Md3Colors.primarySoft);
    expect(theme.colorScheme.secondary, Md3Colors.accent);
    expect(theme.colorScheme.surface, Md3Colors.surface);
    expect(theme.colorScheme.error, Md3Colors.danger);
    expect(theme.textTheme.displayLarge?.fontSize, 32);
    expect(theme.textTheme.headlineMedium?.fontSize, 24);
    expect(theme.textTheme.bodyLarge?.fontSize, 16);
  });

  test('Discover source labels use clear member-facing language', () {
    expect(
      MovieListCurator.sourceNoteForPurpose(
        CuratedMovieListPurpose.popularMovies,
      ),
      'Popular with MovieDiary members · released titles',
    );
    expect(
      MovieListCurator.sourceNoteForPurpose(
        CuratedMovieListPurpose.popularTv,
      ),
      'Popular with MovieDiary members · released titles',
    );
  });

  testWidgets(
    'interactive chips and expandable copy pass compact large-text targets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const longStory =
          'A linguist is recruited to communicate with visitors after '
          'mysterious spacecraft appear around the world. As nations move '
          'closer to conflict, she must understand a new language, confront '
          'her memories, and decide whether trust can change the future.';

      await tester.pumpWidget(
        MaterialApp(
          theme: MovieDiaryTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      key: const Key('interactive-chip-target'),
                      child: Md3Chip(
                        text: 'Liked',
                        active: true,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Md3ExpandableText(
                      text: longStory,
                      style: TextStyle(
                        color: Md3Colors.text,
                        fontSize: 16,
                        height: 23 / 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.getSize(find.byKey(const Key('interactive-chip-target'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(find.text('Show more'), findsOneWidget);

      final collapsedStory = tester.widget<Text>(find.text(longStory));
      expect(collapsedStory.maxLines, 5);

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
      final expandedStory = tester.widget<Text>(find.text(longStory));
      expect(expandedStory.maxLines, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
