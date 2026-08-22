import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Objects/user_taste_profile.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/movie_dna_profile.dart';

void main() {
  test('MovieDNA profile trust labels follow rating evidence bands', () {
    expect(movieDnaProfileReadLabel(10), 'Early read');
    expect(movieDnaProfileReadLabel(25), 'Developing profile');
    expect(movieDnaProfileReadLabel(50), 'Strong read');
    expect(movieDnaProfileReadLabel(150), 'Very strong read');
  });

  testWidgets('MovieDNA preview stays concise and exposes top traits', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpMovieDna(tester, textScale: 1);

    final preview = find.byKey(const Key('moviedna-trait-preview'));
    expect(preview, findsOneWidget);
    expect(
      find.descendant(of: preview, matching: find.text('Superhero fan')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preview, matching: find.text('Cross-format regular')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preview, matching: find.text('Era-hopping explorer')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preview, matching: find.text('Sci-fi worldbuilder')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('MovieDNA details explain evidence at modest larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 930));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpMovieDna(tester, textScale: 1.3);

    expect(find.byKey(const Key('moviedna-details')), findsOneWidget);
    expect(find.text('What your ratings reveal'), findsOneWidget);
    expect(find.textContaining('Very strong read · 28 likes · 3 dislikes'),
        findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey('moviedna-insight-superhero-stories'),
            ),
          )
          .label,
      isNot(contains('%')),
    );
    expect(find.text('For your next deck'), findsOneWidget);
    final rateMore = find.text('Rate more');
    await tester.ensureVisible(rateMore);
    await tester.pump();
    expect(
        tester
            .getSize(
                find.ancestor(of: rateMore, matching: find.byType(TextButton)))
            .height,
        greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MovieDNA detail count follows the 3, 4, and 5 trait bands', (
    tester,
  ) async {
    for (final testCase in const [(10, 3), (50, 4), (150, 5)]) {
      final profile = _profileWithRatings(testCase.$1);
      await _pumpMovieDna(
        tester,
        textScale: 1,
        profile: profile,
      );

      for (var index = 0; index < _profile.insights.length; index++) {
        expect(
          find.byKey(
            ValueKey('moviedna-insight-${_profile.insights[index].key}'),
          ),
          index < testCase.$2 ? findsOneWidget : findsNothing,
        );
      }
    }
  });
}

Future<void> _pumpMovieDna(
  WidgetTester tester, {
  required double textScale,
  UserTasteProfile profile = _profile,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MovieDiaryTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MovieDnaTraitPreview(insights: profile.insights),
              const SizedBox(height: 16),
              MovieDnaDetails(profile: profile, onRateMore: () {}),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

UserTasteProfile _profileWithRatings(int ratingsCount) {
  return UserTasteProfile(
    isReady: true,
    isGenerated: true,
    ratingsCount: ratingsCount,
    movieRatingsCount: (ratingsCount * 0.7).round(),
    tvRatingsCount: ratingsCount - (ratingsCount * 0.7).round(),
    profileConfidencePercent: 94,
    recommendationAdvice: _profile.recommendationAdvice,
    insights: _profile.insights,
  );
}

const _profile = UserTasteProfile(
  isReady: true,
  isGenerated: true,
  ratingsCount: 232,
  movieRatingsCount: 169,
  tvRatingsCount: 63,
  profileConfidencePercent: 94,
  recommendationAdvice: [
    'Recommendations can lean into superhero fan and cross-format regular without repeating the same titles.',
    'Balanced discovery can add one well-grounded surprise.',
  ],
  insights: [
    MovieDnaInsight(
      key: 'superhero-stories',
      label: 'Superhero fan',
      description:
          'Heroic team-ups and comic-book worlds repeatedly earn your likes.',
      category: 'story_theme',
      confidencePercent: 91,
      positiveEvidenceCount: 28,
      counterEvidenceCount: 3,
      supportingTitles: ['Spider-Verse', 'The Avengers', 'The Batman'],
    ),
    MovieDnaInsight(
      key: 'cross-format',
      label: 'Cross-format regular',
      description: 'Movies and TV both contribute meaningful favorites.',
      category: 'format',
      confidencePercent: 89,
      positiveEvidenceCount: 74,
      counterEvidenceCount: 0,
      supportingTitles: ['Arrival', 'Severance'],
    ),
    MovieDnaInsight(
      key: 'era-hopping',
      label: 'Era-hopping explorer',
      description:
          'Your likes span several decades instead of clustering in one period.',
      category: 'era_international',
      confidencePercent: 88,
      positiveEvidenceCount: 120,
      counterEvidenceCount: 0,
      supportingTitles: ['Alien', 'The Matrix', 'Dune'],
    ),
    MovieDnaInsight(
      key: 'genre-science-fiction',
      label: 'Sci-fi worldbuilder',
      description: 'Science Fiction repeats across your strongest reactions.',
      category: 'genre_franchise',
      confidencePercent: 86,
      positiveEvidenceCount: 45,
      counterEvidenceCount: 4,
      supportingTitles: ['Arrival', 'Blade Runner 2049'],
    ),
    MovieDnaInsight(
      key: 'epic-runtime',
      label: 'Epic-runtime fan',
      description:
          'Long-form stories repeatedly earn your strongest reactions.',
      category: 'mood_pacing',
      confidencePercent: 84,
      positiveEvidenceCount: 24,
      counterEvidenceCount: 2,
      supportingTitles: ['Dune', 'The Godfather'],
    ),
  ],
);
