import 'package:flutter/material.dart';
import 'package:mmobile/Objects/user_taste_profile.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

const _movieDnaReadLevels = [
  'Early read',
  'Developing profile',
  'Strong read',
  'Very strong read',
];

int movieDnaTraitLimit(int ratingsCount) {
  return ratingsCount < 50 ? 3 : (ratingsCount < 150 ? 4 : 5);
}

String movieDnaProfileReadLabel(int ratingsCount) {
  return _movieDnaReadLevels[_movieDnaRatingsTier(ratingsCount)];
}

int _movieDnaRatingsTier(int ratingsCount) {
  if (ratingsCount < 25) return 0;
  if (ratingsCount < 50) return 1;
  if (ratingsCount < 150) return 2;
  return 3;
}

String _movieDnaInsightReadLabel(
  MovieDnaInsight insight,
  int ratingsCount,
) {
  final evidenceTier = switch (insight.positiveEvidenceCount) {
    < 5 => 0,
    < 10 => 1,
    < 20 => 2,
    _ => 3,
  };
  var tier = evidenceTier < _movieDnaRatingsTier(ratingsCount)
      ? evidenceTier
      : _movieDnaRatingsTier(ratingsCount);
  if (tier > 0 &&
      insight.counterEvidenceCount > 0 &&
      insight.counterEvidenceCount * 2 >= insight.positiveEvidenceCount) {
    tier--;
  }
  return _movieDnaReadLevels[tier];
}

class MovieDnaTraitPreview extends StatelessWidget {
  final List<MovieDnaInsight> insights;
  final List<String> fallbackLabels;

  const MovieDnaTraitPreview({
    super.key,
    required this.insights,
    this.fallbackLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final labels = insights.isNotEmpty
        ? insights.take(3).map((insight) => insight.label).toList()
        : fallbackLabels.take(3).toList();
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Top MovieDNA traits: ${labels.join(', ')}',
      child: Wrap(
        key: const Key('moviedna-trait-preview'),
        spacing: 7,
        runSpacing: 7,
        children: [
          for (var index = 0; index < labels.length; index++)
            Container(
              constraints: const BoxConstraints(minHeight: 32),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    index == 0 ? Md3Colors.primarySoft : Md3Colors.neutralSoft,
                borderRadius: BorderRadius.circular(Md3Radius.input),
                border: Border.all(
                  color: index == 0
                      ? Md3Colors.primary.withValues(alpha: 0.14)
                      : Md3Colors.border,
                ),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  color: index == 0 ? Md3Colors.primary : Md3Colors.text,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MovieDnaDetails extends StatelessWidget {
  final UserTasteProfile profile;
  final VoidCallback onRateMore;

  const MovieDnaDetails({
    super.key,
    required this.profile,
    required this.onRateMore,
  });

  @override
  Widget build(BuildContext context) {
    final insights = profile.insights
        .take(movieDnaTraitLimit(profile.ratingsCount))
        .toList();
    return Column(
      key: const Key('moviedna-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insights.isNotEmpty) ...[
          const Text(
            'What your ratings reveal',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 14,
              height: 19 / 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < insights.length; index++) ...[
            _MovieDnaInsightRow(
              insight: insights[index],
              ratingsCount: profile.ratingsCount,
            ),
            if (index != insights.length - 1) const SizedBox(height: 8),
          ],
        ],
        if (profile.recommendationAdvice.isNotEmpty) ...[
          const SizedBox(height: Md3Spacing.x16),
          const Text(
            'For your next deck',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 14,
              height: 19 / 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final advice in profile.recommendationAdvice.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: Md3Colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.data_usage_rounded,
              size: 17,
              color: Md3Colors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _ratingsBasis(profile),
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 12,
                  height: 17 / 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Md3Colors.primary,
                minimumSize: const Size.square(Md3Targets.minimum),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: onRateMore,
              child: const Text('Rate more'),
            ),
          ],
        ),
      ],
    );
  }

  static String _ratingsBasis(UserTasteProfile profile) {
    final parts = <String>[];
    if (profile.movieRatingsCount > 0) {
      parts.add(
        '${profile.movieRatingsCount} ${profile.movieRatingsCount == 1 ? 'movie' : 'movies'}',
      );
    }
    if (profile.tvRatingsCount > 0) {
      parts.add(
        '${profile.tvRatingsCount} TV ${profile.tvRatingsCount == 1 ? 'show' : 'shows'}',
      );
    }
    final basis = parts.isEmpty
        ? '${profile.ratingsCount} rated ${profile.ratingsCount == 1 ? 'title' : 'titles'}'
        : parts.join(' and ');
    return 'Based on $basis. More varied ratings make this read sharper.';
  }
}

class _MovieDnaInsightRow extends StatelessWidget {
  final MovieDnaInsight insight;
  final int ratingsCount;

  const _MovieDnaInsightRow({
    required this.insight,
    required this.ratingsCount,
  });

  @override
  Widget build(BuildContext context) {
    final evidence = <String>[
      _movieDnaInsightReadLabel(insight, ratingsCount),
      '${insight.positiveEvidenceCount} ${insight.positiveEvidenceCount == 1 ? 'like' : 'likes'}',
      if (insight.counterEvidenceCount > 0)
        '${insight.counterEvidenceCount} ${insight.counterEvidenceCount == 1 ? 'dislike' : 'dislikes'}',
    ].join(' · ');
    final titleEvidence = insight.supportingTitles.take(3).join(', ');

    return Semantics(
      container: true,
      label: [
        insight.label,
        insight.description,
        'Why this? $evidence',
        if (titleEvidence.isNotEmpty) 'Examples: $titleEvidence',
      ].join('. '),
      child: Container(
        key: ValueKey('moviedna-insight-${insight.key}'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Md3Colors.surfaceMuted,
          borderRadius: BorderRadius.circular(Md3Radius.input),
          border: Border.all(color: Md3Colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Md3Colors.primarySoft,
                borderRadius: BorderRadius.circular(Md3Radius.medium),
              ),
              child: Icon(
                _iconForCategory(insight.category),
                color: Md3Colors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.label,
                    style: const TextStyle(
                      color: Md3Colors.text,
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    insight.description,
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 13,
                      height: 18 / 13,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Why this? $evidence',
                    style: const TextStyle(
                      color: Md3Colors.primary,
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (titleEvidence.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      titleEvidence,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForCategory(String category) {
    return switch (category) {
      'story_theme' => Icons.auto_stories_rounded,
      'mood_pacing' => Icons.speed_rounded,
      'genre_franchise' => Icons.movie_filter_rounded,
      'era_international' => Icons.public_rounded,
      'format' => Icons.live_tv_rounded,
      'discovery_appetite' => Icons.explore_rounded,
      _ => Icons.insights_rounded,
    };
  }
}
