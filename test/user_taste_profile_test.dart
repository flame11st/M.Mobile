import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Objects/user_taste_profile.dart';

void main() {
  test('MovieDNA insights are additive and old payloads remain compatible', () {
    final legacy = UserTasteProfile.fromJson({
      'isReady': true,
      'isGenerated': true,
      'ratingsCount': 12,
      'favoriteGenres': ['Drama'],
    });
    final movieDna = UserTasteProfile.fromJson({
      'isReady': true,
      'isGenerated': true,
      'ratingsCount': 232,
      'insights': [
        {
          'key': 'superhero-stories',
          'label': 'Superhero fan',
          'description': 'Team-up stories keep earning your likes.',
          'category': 'story_theme',
          'confidencePercent': 91,
          'positiveEvidenceCount': 28,
          'counterEvidenceCount': 3,
          'supportingTitleIds': ['a', 'b'],
          'supportingTitles': ['Alpha', 'Beta'],
        },
      ],
    });

    expect(legacy.insights, isEmpty);
    expect(legacy.favoriteGenres, ['Drama']);
    expect(movieDna.insights, hasLength(1));
    expect(movieDna.insights.single.label, 'Superhero fan');
    expect(movieDna.insights.single.supportingTitles, ['Alpha', 'Beta']);
    expect(movieDna.insights.single.positiveEvidenceCount, 28);
  });
}
