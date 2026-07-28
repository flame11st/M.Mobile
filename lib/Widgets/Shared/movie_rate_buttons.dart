import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:provider/provider.dart';

class MovieRateButtons extends StatelessWidget {
  final bool? showTitle;
  final bool? addMargin;
  final bool? fromSearch;
  final bool closeParentOnRate;
  final Movie movie;
  final bool shouldRequestReview;
  final MoviesList? moviesList;

  const MovieRateButtons({
    super.key,
    this.showTitle,
    this.addMargin,
    this.fromSearch = false,
    this.closeParentOnRate = true,
    required this.movie,
    this.shouldRequestReview = false,
    this.moviesList,
  });

  @override
  Widget build(BuildContext context) {
    final isTitledSheet = showTitle != null && showTitle!;
    final moviesState = Provider.of<MoviesState>(context);
    final matchingMovies =
        moviesState.userMovies.where((element) => element.id == movie.id);
    final currentMovie =
        matchingMovies.isNotEmpty ? matchingMovies.first : movie;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTitledSheet) ...[
          Text(
            currentMovie.movieRate == MovieRate.notRated
                ? 'Set your status'
                : 'Change your status',
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentMovie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _RateAction(
                label: 'Liked',
                icon: Icons.favorite_rounded,
                color: Md3Colors.success,
                active: currentMovie.movieRate == MovieRate.liked,
                onTap: () => _rate(context, currentMovie, MovieRate.liked),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RateAction(
                label: 'Okay',
                icon: Icons.sentiment_satisfied_alt_rounded,
                color: Md3Colors.warning,
                active: currentMovie.movieRate == MovieRate.okay,
                onTap: () => _rate(context, currentMovie, MovieRate.okay),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RateAction(
                label: 'Disliked',
                icon: FontAwesome5.ban,
                color: Md3Colors.danger,
                active: currentMovie.movieRate == MovieRate.notLiked,
                onTap: () => _rate(context, currentMovie, MovieRate.notLiked),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RateAction(
                label: 'Watchlist',
                icon: Icons.bookmark_rounded,
                color: Md3Colors.primary,
                active: currentMovie.movieRate == MovieRate.addedToWatchlist,
                onTap: () => _rate(
                  context,
                  currentMovie,
                  MovieRate.addedToWatchlist,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (!isTitledSheet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: content,
      );
    }

    return Md3BottomSheetSurface(child: content);
  }

  Future<void> _rate(
    BuildContext context,
    Movie currentMovie,
    int selectedRate,
  ) async {
    final navigator = Navigator.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final previousMovieRate = currentMovie.movieRate;
    final nextMovieRate =
        previousMovieRate == selectedRate ? MovieRate.notRated : selectedRate;

    await moviesState.changeMovieRate(
      currentMovie.id,
      nextMovieRate,
      userState.isIncognitoMode,
      currentMovie,
    );

    if (!userState.isIncognitoMode && ServiceAgent.state != null) {
      await ServiceAgent().rateMovie(
        currentMovie.id,
        userState.userId!,
        nextMovieRate,
      );
    }

    if (closeParentOnRate && navigator.canPop()) {
      navigator.pop();
    }

    if (fromSearch == true && navigator.canPop()) {
      navigator.pop();
    }

    if (shouldRequestReview || fromSearch == true) {
      userState.shouldRequestReview = true;
    }

    await Future.delayed(const Duration(milliseconds: 250));
    MSnackBar.showSnackBar(
      _buildStatusMessage(previousMovieRate, nextMovieRate),
      true,
    );
  }

  String _buildStatusMessage(int previousMovieRate, int nextMovieRate) {
    final movieTitle = '"${movie.title}"';

    if (nextMovieRate == MovieRate.addedToWatchlist) {
      if (previousMovieRate == MovieRate.addedToWatchlist) {
        return '$movieTitle is already in Watchlist.';
      }

      if (MovieRate.isViewed(previousMovieRate)) {
        return '$movieTitle moved to Watchlist.';
      }

      return '$movieTitle added to Watchlist.';
    }

    if (nextMovieRate == MovieRate.notRated) {
      if (previousMovieRate == MovieRate.addedToWatchlist) {
        return '$movieTitle removed from Watchlist.';
      }

      if (MovieRate.isViewed(previousMovieRate)) {
        return '$movieTitle removed from Viewed.';
      }

      return '$movieTitle removed from My Movies.';
    }

    if (MovieRate.isViewed(nextMovieRate)) {
      final label = MovieRate.opinionLabel(nextMovieRate);

      if (MovieRate.isViewed(previousMovieRate)) {
        return '$movieTitle saved as $label.';
      }

      if (previousMovieRate == MovieRate.addedToWatchlist) {
        return '$movieTitle moved to Viewed. Saved as $label.';
      }

      return '$movieTitle saved as $label.';
    }

    return '$movieTitle status updated.';
  }
}

class _RateAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _RateAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = active ? Colors.white : Md3Colors.muted;
    final background = active ? color : Colors.white.withValues(alpha: 0.78);
    final borderColor = active ? color : Md3Colors.border;

    return Semantics(
      button: true,
      selected: active,
      label: '$label status',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: active ? 1.5 : 1),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 19),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
