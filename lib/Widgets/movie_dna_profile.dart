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

const _genericMovieDnaInsightKeys = {
  'cross-format',
  'wide-ranging',
  'recent-releases',
};

List<MovieDnaInsight> movieDnaPresentationInsights(
  Iterable<MovieDnaInsight> insights,
) {
  final candidates = insights
      .where((insight) =>
          insight.key.trim().isNotEmpty && insight.label.trim().isNotEmpty)
      .toList();
  final deduplicated = <MovieDnaInsight>[];
  final semanticIndexes = <String, int>{};
  for (final insight in candidates) {
    final group = _movieDnaSemanticGroup(insight.key.toLowerCase());
    final existingIndex = group == null ? null : semanticIndexes[group];
    if (existingIndex == null) {
      if (group != null) semanticIndexes[group] = deduplicated.length;
      deduplicated.add(insight);
      continue;
    }
    if (_movieDnaEvidenceScore(insight) >
        _movieDnaEvidenceScore(deduplicated[existingIndex])) {
      deduplicated[existingIndex] = insight;
    }
  }
  final ordered = [
    ...deduplicated.where(
      (insight) => !_genericMovieDnaInsightKeys.contains(insight.key),
    ),
    ...deduplicated.where(
      (insight) => _genericMovieDnaInsightKeys.contains(insight.key),
    ),
  ];
  final selected = <MovieDnaInsight>[];
  final seenKeys = <String>{};

  for (final insight in ordered) {
    final key = insight.key.toLowerCase();
    if (!seenKeys.add(key)) {
      continue;
    }
    selected.add(insight);
  }

  return selected;
}

int _movieDnaEvidenceScore(MovieDnaInsight insight) {
  return (insight.positiveEvidenceCount - insight.counterEvidenceCount) * 1000 +
      insight.confidencePercent;
}

String? _movieDnaSemanticGroup(String key) {
  if (key == 'global-cinema' ||
      key.contains('international') ||
      key.contains('foreign-language') ||
      key.contains('world-language') ||
      key.contains('global-language')) {
    return 'international-cinema';
  }
  return null;
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
  final int maxTraits;

  const MovieDnaTraitPreview({
    super.key,
    required this.insights,
    this.fallbackLabels = const [],
    this.maxTraits = 3,
  });

  @override
  Widget build(BuildContext context) {
    final presentedInsights = movieDnaPresentationInsights(insights);
    final traitLimit = maxTraits < 1 ? 1 : (maxTraits > 3 ? 3 : maxTraits);
    final labels = presentedInsights.isNotEmpty
        ? presentedInsights
            .take(traitLimit)
            .map((insight) => insight.label)
            .toList()
        : fallbackLabels.take(traitLimit).toList();
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Top MovieDNA traits: ${labels.join(', ')}',
      excludeSemantics: true,
      child: Wrap(
        key: const Key('moviedna-trait-preview'),
        spacing: 8,
        runSpacing: 8,
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

class MovieDnaDetails extends StatefulWidget {
  final UserTasteProfile profile;
  final VoidCallback onRateMore;

  const MovieDnaDetails({
    super.key,
    required this.profile,
    required this.onRateMore,
  });

  @override
  State<MovieDnaDetails> createState() => _MovieDnaDetailsState();
}

class _MovieDnaDetailsState extends State<MovieDnaDetails> {
  bool _showAllInsights = false;

  @override
  Widget build(BuildContext context) {
    final allInsights = movieDnaPresentationInsights(widget.profile.insights);
    final initialCount = movieDnaTraitLimit(widget.profile.ratingsCount);
    final insights = allInsights
        .take(_showAllInsights ? allInsights.length : initialCount)
        .toList();
    return Container(
      key: const Key('moviedna-details'),
      width: double.infinity,
      color: Md3Colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insights.isNotEmpty) ...[
            const Text(
              'What your ratings reveal',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < insights.length; index++) ...[
              _MovieDnaInsightRow(
                insight: insights[index],
                ratingsCount: widget.profile.ratingsCount,
              ),
              if (index != insights.length - 1)
                const Divider(height: 1, color: Md3Colors.border),
            ],
            if (allInsights.length > initialCount) ...[
              const Divider(height: 1, color: Md3Colors.border),
              SizedBox(
                height: Md3Targets.minimum,
                child: TextButton.icon(
                  key: const Key('moviedna-show-more-insights'),
                  style: TextButton.styleFrom(
                    foregroundColor: Md3Colors.primary,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: () {
                    setState(() => _showAllInsights = !_showAllInsights);
                  },
                  icon: Icon(
                    _showAllInsights
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _showAllInsights
                        ? 'Show fewer insights'
                        : 'Show more insights',
                  ),
                ),
              ),
            ],
          ],
          if (widget.profile.recommendationAdvice.isNotEmpty) ...[
            const Divider(height: 1, color: Md3Colors.border),
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
            for (final advice in widget.profile.recommendationAdvice.take(2))
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
                  _ratingsBasis(widget.profile),
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
                onPressed: widget.onRateMore,
                child: const Text('Rate more'),
              ),
            ],
          ),
        ],
      ),
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
      excludeSemantics: true,
      label: [
        insight.label,
        insight.description,
        'Why this? $evidence',
        if (titleEvidence.isNotEmpty) 'Examples: $titleEvidence',
      ].join('. '),
      child: Padding(
        key: ValueKey('moviedna-insight-${insight.key}'),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Md3Colors.primarySoft,
                borderRadius: BorderRadius.circular(Md3Radius.medium),
              ),
              child: Icon(
                _iconForCategory(insight.category),
                color: Md3Colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.label,
                    style: const TextStyle(
                      color: Md3Colors.text,
                      fontSize: 18,
                      height: 23 / 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.description,
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 15,
                      height: 21 / 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Why this? $evidence',
                    style: const TextStyle(
                      color: Md3Colors.primary,
                      fontSize: 14,
                      height: 19 / 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (titleEvidence.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      titleEvidence,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 14,
                        height: 19 / 14,
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
