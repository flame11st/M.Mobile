import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

/// Compact Discover/details ratings. Personal state belongs to status controls.
class MovieCommunitySignal extends StatelessWidget {
  final String label;
  final String? semanticsLabel;

  const MovieCommunitySignal({
    super.key,
    required this.label,
    this.semanticsLabel,
  });

  static MovieCommunitySignal? forMovie(Movie movie) {
    final md = communityLabel(movie);
    final imdb = imdbLabel(movie);
    if (md == null && imdb == null) return null;
    final count = movie.scoreCount;
    final percentage = md == null
        ? null
        : RegExp(r'\d+%').firstMatch(md)?.group(0);
    return MovieCommunitySignal(
      label: [if (md != null) md, if (imdb != null) imdb].join(' · '),
      semanticsLabel: [
        if (md != null)
          'MovieDiary community: ${[if (percentage != null) percentage, if (count != null && count > 0) '$count ${count == 1 ? 'rating' : 'ratings'}'].join(', ')}',
        if (imdb != null) '$imdb out of 10',
      ].join('. '),
    );
  }

  static String? communityLabel(Movie movie) {
    if (movie.scoreSource?.trim().toLowerCase() != 'moviediary') return null;
    // An explicit zero count means there is no community rating yet.
    if (movie.scoreCount != null && movie.scoreCount! <= 0) return null;
    final value = movie.scoreValue;
    final scale = movie.scoreScale?.trim().toLowerCase();
    final isPercentage = const ['percent', 'percentage', '100'].contains(scale);
    final percentage =
        isPercentage &&
            value != null &&
            value.isFinite &&
            value >= 0 &&
            value <= 100
        ? '${value.round()}%'
        : null;
    final count = movie.scoreCount;
    final ratings = count != null && count > 0
        ? '(${NumberFormat.decimalPattern('en_US').format(count)})'
        : null;
    if (percentage == null && ratings == null) return null;
    return 'MD ${[if (percentage != null) percentage, if (ratings != null) ratings].join(' ')}';
  }

  static String? imdbLabel(Movie movie) {
    final rating = movie.imdbRate;
    if (!rating.isFinite || rating <= 0 || rating > 10) return null;
    return 'IMDb ${rating.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) => Text(
    label,
    key: const Key('movie-community-signal'),
    semanticsLabel: semanticsLabel ?? label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: Md3Colors.muted,
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w600,
    ),
  );
}
