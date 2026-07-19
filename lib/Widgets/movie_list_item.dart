import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/Shared/movie_rate_buttons.dart';
import 'package:mmobile/Widgets/mark_watched_bottom_sheet.dart';
import 'package:mmobile/Widgets/movie_list_item_expanded.dart';
import 'package:mmobile/Widgets/movies_lists_page.dart';
import 'package:provider/provider.dart';

enum MovieCardMode {
  browse,
  watchlist,
  viewed,
  personalList,
}

class MovieListItem extends StatelessWidget {
  final Movie movie;
  final MoviesList? moviesList;
  final bool shouldRequestReview;
  final MovieCardMode mode;

  const MovieListItem({
    super.key,
    required this.movie,
    this.moviesList,
    this.shouldRequestReview = false,
    this.mode = MovieCardMode.browse,
  });

  @override
  Widget build(BuildContext context) {
    Provider.of<MoviesState>(context);

    return Hero(
      tag: 'movie-hero-animation${movie.id}',
      child: Material(
        color: Colors.transparent,
        child: Md3Card(
          margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
          padding: const EdgeInsets.all(10),
          onTap: () => _openDetails(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Md3MoviePoster(movie: movie, width: 64, height: 96),
              const SizedBox(width: 12),
              Expanded(child: _MovieCardSummary(movie: movie)),
              const SizedBox(width: 8),
              _buildAction(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    if (mode == MovieCardMode.personalList) {
      return _CardIconAction(
        tooltip: 'Movie actions',
        icon: Icons.more_horiz_rounded,
        foreground: Md3Colors.primary,
        background: Md3Colors.primarySoft,
        onPressed: () => _openActionsSheet(context),
      );
    }

    if (mode == MovieCardMode.watchlist ||
        movie.movieRate == MovieRate.addedToWatchlist) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CardTextAction(
            label: 'Mark\nWatched',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () => _openMarkWatchedSheet(context),
          ),
          const SizedBox(width: 8),
          _CardIconAction(
            tooltip: 'More actions',
            icon: Icons.more_horiz_rounded,
            foreground: Md3Colors.primary,
            background: Md3Colors.primarySoft,
            onPressed: () => _openActionsSheet(context),
          ),
        ],
      );
    }

    if (mode == MovieCardMode.viewed || MovieRate.isViewed(movie.movieRate)) {
      return _CardIconAction(
        tooltip: 'Movie actions',
        icon: Icons.more_horiz_rounded,
        foreground: Md3Colors.primary,
        background: Md3Colors.primarySoft,
        onPressed: () => _openActionsSheet(context),
      );
    }

    return _CardIconAction(
      tooltip: 'Movie actions',
      icon: Icons.more_horiz_rounded,
      foreground: Md3Colors.primary,
      background: Md3Colors.primarySoft,
      onPressed: () => _openActionsSheet(context),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MovieListItemExpanded(
          movie: movie,
          imageUrl: 'https://moviediarystorage.blob.core.windows.net/movies',
          moviesList: moviesList,
          shouldRequestReview: shouldRequestReview,
        ),
      ),
    );
  }

  void _openMarkWatchedSheet(BuildContext context) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => MarkWatchedBottomSheet(movie: movie),
    );
  }

  void _openActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (context) => _MovieRowActionsSheet(
        movie: movie,
        moviesList: moviesList,
        mode: mode,
        shouldRequestReview: shouldRequestReview,
        onOpenDetails: () {
          Navigator.of(context).pop();
          _openDetails(context);
        },
      ),
    );
  }
}

class _MovieRowActionsSheet extends StatelessWidget {
  final Movie movie;
  final MoviesList? moviesList;
  final MovieCardMode mode;
  final bool shouldRequestReview;
  final VoidCallback onOpenDetails;

  const _MovieRowActionsSheet({
    required this.movie,
    required this.moviesList,
    required this.mode,
    required this.shouldRequestReview,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final matchingMovies =
        moviesState.userMovies.where((element) => element.id == movie.id);
    final currentMovie =
        matchingMovies.isNotEmpty ? matchingMovies.first : movie;
    final isWatchlist = currentMovie.movieRate == MovieRate.addedToWatchlist ||
        mode == MovieCardMode.watchlist;
    final isViewed = MovieRate.isViewed(currentMovie.movieRate);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Md3Colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Md3MoviePoster(movie: currentMovie, width: 46, height: 68),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Movie actions',
                          style: TextStyle(
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (currentMovie.movieRate != MovieRate.notRated) ...[
                const SizedBox(height: 14),
                Md3OpinionBadge(movieRate: currentMovie.movieRate),
              ],
              const SizedBox(height: 18),
              if (isWatchlist)
                _SheetActionButton(
                  label: 'Mark watched',
                  detail: 'Move to Viewed and save your opinion.',
                  icon: Icons.check_circle_outline_rounded,
                  color: Md3Colors.primary,
                  filled: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet<void>(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) =>
                          MarkWatchedBottomSheet(movie: currentMovie),
                    );
                  },
                )
              else
                _SheetActionButton(
                  label: 'Add to Watchlist',
                  detail: 'Save it for later without rating it yet.',
                  icon: Icons.bookmark_add_rounded,
                  color: Md3Colors.primary,
                  filled: true,
                  onTap: () => _rate(
                    context,
                    currentMovie,
                    MovieRate.addedToWatchlist,
                  ),
                ),
              const SizedBox(height: 12),
              _SheetActionButton(
                label: isViewed ? 'Change rating' : 'Rate now',
                detail: 'Pick Liked, Okay, or Disliked.',
                icon: Icons.favorite_rounded,
                color: Md3Colors.success,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) => MovieRateButtons(
                      moviesList: moviesList,
                      movie: currentMovie,
                      showTitle: true,
                      addMargin: false,
                      shouldRequestReview: shouldRequestReview,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PersonalListAction(movie: currentMovie, moviesList: moviesList),
              const SizedBox(height: 12),
              _SheetActionButton(
                label: 'View details',
                detail: 'Open cast, story, ratings, and where to watch.',
                icon: Icons.info_outline_rounded,
                color: Md3Colors.muted,
                onTap: onOpenDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rate(
    BuildContext context,
    Movie currentMovie,
    int selectedRate,
  ) async {
    final navigator = Navigator.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    await moviesState.changeMovieRate(
      currentMovie.id,
      selectedRate,
      userState.isIncognitoMode,
      currentMovie,
    );

    if (!userState.isIncognitoMode && userState.userId != null) {
      await ServiceAgent().rateMovie(
        currentMovie.id,
        userState.userId!,
        selectedRate,
      );
    }

    if (!context.mounted) {
      return;
    }

    navigator.pop();
    MSnackBar.showSnackBar('Added to Watchlist.', true);
  }
}

class _PersonalListAction extends StatelessWidget {
  final Movie movie;
  final MoviesList? moviesList;

  const _PersonalListAction({
    required this.movie,
    required this.moviesList,
  });

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userLists = [...moviesState.personalMoviesLists]
      ..sort((a, b) => a.order.compareTo(b.order));

    if (moviesList != null) {
      return _SheetActionButton(
        label: 'Remove from ${moviesList!.name}',
        detail: 'Keep the movie status, but remove it from this list.',
        icon: Icons.remove_circle_outline_rounded,
        color: Md3Colors.danger,
        onTap: () => _removeFromList(context, moviesList!),
      );
    }

    if (userLists.isEmpty) {
      return _SheetActionButton(
        label: 'Create a personal list',
        detail: 'Open Lists to make a collection first.',
        icon: Icons.playlist_add_rounded,
        color: Md3Colors.primary,
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MoviesListsPage(initialPageIndex: 1),
            ),
          );
        },
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        leading: const _SheetActionIcon(
          icon: Icons.playlist_add_rounded,
          color: Md3Colors.primary,
        ),
        title: const Text(
          'Add to personal list',
          style: TextStyle(
            color: Md3Colors.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: const Text(
          'Choose one of your lists.',
          style: TextStyle(
            color: Md3Colors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          for (final list in userLists)
            _ListChoice(movie: movie, moviesList: list),
        ],
      ),
    );
  }

  Future<void> _removeFromList(BuildContext context, MoviesList list) async {
    final navigator = Navigator.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    if (!userState.isIncognitoMode && userState.userId != null) {
      await ServiceAgent().removeMovieFromList(
        userState.userId!,
        movie.id,
        list.name,
      );
    }

    moviesState.removeMovieFromPersonalList(list.name, movie);

    if (!context.mounted) {
      return;
    }

    navigator.pop();
    MSnackBar.showSnackBar('Removed from ${list.name}.', true);
  }
}

class _ListChoice extends StatelessWidget {
  final Movie movie;
  final MoviesList moviesList;

  const _ListChoice({
    required this.movie,
    required this.moviesList,
  });

  @override
  Widget build(BuildContext context) {
    final movieInList =
        moviesList.listMovies.any((element) => element.id == movie.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: movieInList ? Md3Colors.surfaceMuted : Md3Colors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: movieInList ? null : () => _addToList(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Md3Colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moviesList.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Md3Colors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${moviesList.listMovies.length} item${moviesList.listMovies.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Md3Colors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  movieInList
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: movieInList ? Md3Colors.success : Md3Colors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToList(BuildContext context) async {
    final navigator = Navigator.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    if (!userState.isIncognitoMode && userState.userId != null) {
      await ServiceAgent().addMovieToList(
        userState.userId!,
        movie.id,
        moviesList.name,
      );
    }

    moviesState.addMovieToPersonalList(moviesList.name, movie);

    if (!context.mounted) {
      return;
    }

    navigator.pop();
    MSnackBar.showSnackBar('Added to ${moviesList.name}.', true);
  }
}

class _SheetActionButton extends StatelessWidget {
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _SheetActionButton({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled ? color : Md3Colors.background;
    final foreground = filled ? Colors.white : Md3Colors.text;
    final detailColor =
        filled ? Colors.white.withValues(alpha: 0.82) : Md3Colors.muted;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: filled ? color : Md3Colors.border),
          ),
          child: Row(
            children: [
              _SheetActionIcon(
                icon: icon,
                color: filled ? Colors.white : color,
                filled: filled,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: detailColor,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: filled ? Colors.white : Md3Colors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;

  const _SheetActionIcon({
    required this.icon,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withValues(alpha: 0.16)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _MovieCardSummary extends StatelessWidget {
  final Movie movie;

  const _MovieCardSummary({required this.movie});

  @override
  Widget build(BuildContext context) {
    final runtime = movie.movieType == MovieType.tv
        ? movie.seasonsCount > 0
            ? '${movie.seasonsCount} season${movie.seasonsCount == 1 ? '' : 's'}'
            : movie.averageTimeOfEpisode > 0
                ? '${movie.averageTimeOfEpisode} min'
                : null
        : movie.duration > 0
            ? '${movie.duration} min'
            : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 17,
              height: 1.14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              _MetadataPill(text: '${movie.releaseDate.year}'),
              if (runtime != null) _MetadataPill(text: runtime),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            movie.genres.isNotEmpty
                ? movie.genres.take(3).join(', ')
                : movie.movieType == MovieType.tv
                    ? 'TV Series'
                    : 'Movie',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (movie.movieRate != MovieRate.notRated) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Md3OpinionBadge(movieRate: movie.movieRate),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  final String text;

  const _MetadataPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      constraints: const BoxConstraints(minHeight: 30),
      decoration: BoxDecoration(
        color: Md3Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Md3Colors.border),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CardIconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback onPressed;

  const _CardIconAction({
    required this.tooltip,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 21),
        ),
      ),
    );
  }
}

class _CardTextAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _CardTextAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          backgroundColor: Md3Colors.primarySoft,
          foregroundColor: Md3Colors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
