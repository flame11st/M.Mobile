import 'dart:io';

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
    final moviesState = Provider.of<MoviesState>(context);
    final matchingMovies =
        moviesState.userMovies.where((element) => element.id == movie.id);
    final currentMovie =
        matchingMovies.isNotEmpty ? matchingMovies.first : movie;
    final mediaQuery = MediaQuery.of(context);
    final isCompactPoster = mediaQuery.size.width <= 390;
    final wrapsPrimaryAction =
        mediaQuery.size.width < 360 || mediaQuery.textScaler.scale(1) >= 1.3;
    final posterWidth = isCompactPoster ? 72.0 : 80.0;
    final posterHeight = isCompactPoster ? 108.0 : 120.0;
    final isWatchlist = mode == MovieCardMode.watchlist;
    final showStatus =
        !isWatchlist && currentMovie.movieRate != MovieRate.notRated;

    return Hero(
      tag: 'movie-hero-animation${movie.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Md3Colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Md3Colors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0f172231),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Semantics(
                          container: true,
                          button: true,
                          excludeSemantics: true,
                          label: 'Open ${currentMovie.title} details',
                          onTap: () => _openDetails(context, currentMovie),
                          child: InkWell(
                            excludeFromSemantics: true,
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openDetails(context, currentMovie),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Md3MoviePoster(
                                  movie: currentMovie,
                                  width: posterWidth,
                                  height: posterHeight,
                                  borderRadius: 12,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MovieCardContent(
                                    movie: currentMovie,
                                    showStatus: showStatus,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CardIconAction(
                        tooltip: 'Movie actions',
                        onPressed: () =>
                            _openActionsSheet(context, currentMovie),
                      ),
                    ],
                  ),
                  if (isWatchlist) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.only(
                        left: wrapsPrimaryAction ? 0 : posterWidth + 12,
                      ),
                      child: SizedBox(
                        width: wrapsPrimaryAction ? double.infinity : 120,
                        child: _MarkWatchedButton(
                          onPressed: () =>
                              _openMarkWatchedSheet(context, currentMovie),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Movie currentMovie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MovieListItemExpanded(
          movie: currentMovie,
          imageUrl: 'https://moviediarystorage.blob.core.windows.net/movies',
          moviesList: moviesList,
          shouldRequestReview: shouldRequestReview,
        ),
      ),
    );
  }

  void _openMarkWatchedSheet(BuildContext context, Movie currentMovie) {
    showMarkWatchedBottomSheet(context: context, movie: currentMovie);
  }

  void _openActionsSheet(BuildContext context, Movie currentMovie) {
    showMd3BottomSheet<void>(
      context: context,
      builder: (sheetContext) => _MovieRowActionsSheet(
        movie: currentMovie,
        moviesList: moviesList,
        mode: mode,
        shouldRequestReview: shouldRequestReview,
        parentContext: context,
        onOpenDetails: () {
          Navigator.of(sheetContext).pop();
          _openDetails(context, currentMovie);
        },
      ),
    );
  }
}

class _MovieCardContent extends StatelessWidget {
  final Movie movie;
  final bool showStatus;

  const _MovieCardContent({
    required this.movie,
    required this.showStatus,
  });

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 17,
              height: 22 / 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetadataPill(text: '${movie.releaseDate.year}'),
            if (runtime != null) _MetadataPill(text: runtime),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          movie.genres.isNotEmpty
              ? movie.genres.take(3).join(', ')
              : movie.movieType == MovieType.tv
                  ? 'TV Series'
                  : 'Movie',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Md3Colors.muted,
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (showStatus) ...[
          const SizedBox(height: 10),
          Md3OpinionBadge(movieRate: movie.movieRate),
        ],
      ],
    );
  }
}

class _MarkWatchedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MarkWatchedButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 44,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: Md3Colors.primarySoft,
          foregroundColor: Md3Colors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Mark watched',
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardIconAction extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;

  const _CardIconAction({
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Semantics(
        container: true,
        button: true,
        label: tooltip,
        onTap: onPressed,
        child: ExcludeSemantics(
          child: IconButton(
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: Md3Colors.primarySoft,
              foregroundColor: Md3Colors.primary,
              minimumSize: const Size(44, 44),
              maximumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onPressed,
            icon: const Icon(Icons.more_horiz_rounded, size: 21),
          ),
        ),
      ),
    );
  }
}

class _MovieRowActionsSheet extends StatefulWidget {
  final Movie movie;
  final MoviesList? moviesList;
  final MovieCardMode mode;
  final bool shouldRequestReview;
  final BuildContext parentContext;
  final VoidCallback onOpenDetails;

  const _MovieRowActionsSheet({
    required this.movie,
    required this.moviesList,
    required this.mode,
    required this.shouldRequestReview,
    required this.parentContext,
    required this.onOpenDetails,
  });

  @override
  State<_MovieRowActionsSheet> createState() => _MovieRowActionsSheetState();
}

class _MovieRowActionsSheetState extends State<_MovieRowActionsSheet> {
  bool _updatingWatchlist = false;

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final matchingMovies = moviesState.userMovies
        .where((element) => element.id == widget.movie.id);
    final currentMovie =
        matchingMovies.isNotEmpty ? matchingMovies.first : widget.movie;
    final isWatchlist = currentMovie.movieRate == MovieRate.addedToWatchlist ||
        widget.mode == MovieCardMode.watchlist;
    final isViewed = MovieRate.isViewed(currentMovie.movieRate);

    return Md3BottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Md3MoviePoster(
                movie: currentMovie,
                width: 46,
                height: 68,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Movie actions',
                      style: TextStyle(
                        color: Md3Colors.text,
                        fontSize: 24,
                        height: 29 / 24,
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
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
          if (currentMovie.movieRate != MovieRate.notRated) ...[
            const SizedBox(height: 12),
            Md3OpinionBadge(movieRate: currentMovie.movieRate),
          ],
          const SizedBox(height: 16),
          if (isWatchlist)
            _SheetActionButton(
              label: 'Mark watched',
              detail: 'Move to Viewed and save your opinion.',
              icon: Icons.check_circle_outline_rounded,
              color: Md3Colors.primary,
              filled: true,
              onTap: () => _openMarkWatched(currentMovie),
            )
          else
            _SheetActionButton(
              label: isViewed ? 'Move to Watchlist' : 'Add to Watchlist',
              detail: isViewed
                  ? 'Your current rating will be removed.'
                  : 'Save it for later.',
              icon: Icons.bookmark_add_rounded,
              color: Md3Colors.primary,
              filled: true,
              busy: _updatingWatchlist,
              onTap: _updatingWatchlist
                  ? null
                  : () => _moveToWatchlist(currentMovie, isViewed: isViewed),
            ),
          const SizedBox(height: 12),
          _SheetActionButton(
            label: isViewed ? 'Change rating' : 'Rate now',
            detail: 'Pick Liked, Okay, or Disliked.',
            icon: Icons.favorite_rounded,
            color: Md3Colors.success,
            onTap: () => _openRating(currentMovie),
          ),
          const SizedBox(height: 12),
          _PersonalListAction(
            movie: currentMovie,
            currentList: widget.moviesList,
          ),
          const SizedBox(height: 12),
          _SheetActionButton(
            label: 'Open details',
            detail: 'Open cast, story, ratings, and where to watch.',
            icon: Icons.info_outline_rounded,
            color: Md3Colors.muted,
            onTap: widget.onOpenDetails,
          ),
          if (widget.moviesList != null) ...[
            const SizedBox(height: 8),
            const Divider(color: Md3Colors.border),
            const SizedBox(height: 8),
            _RemoveFromListAction(
              movie: currentMovie,
              moviesList: widget.moviesList!,
            ),
          ],
        ],
      ),
    );
  }

  void _openMarkWatched(Movie currentMovie) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.parentContext.mounted) {
        showMarkWatchedBottomSheet(
          context: widget.parentContext,
          movie: currentMovie,
        );
      }
    });
  }

  void _openRating(Movie currentMovie) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.parentContext.mounted) {
        return;
      }

      showMd3BottomSheet<void>(
        context: widget.parentContext,
        builder: (context) => MovieRateButtons(
          moviesList: widget.moviesList,
          movie: currentMovie,
          showTitle: true,
          addMargin: false,
          shouldRequestReview: widget.shouldRequestReview,
        ),
      );
    });
  }

  Future<void> _moveToWatchlist(
    Movie currentMovie, {
    required bool isViewed,
  }) async {
    if (isViewed) {
      final ratingLabel = MovieRate.opinionLabel(currentMovie.movieRate);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Move to Watchlist?'),
          content: Text(
            'Your $ratingLabel rating will be removed when '
            '${currentMovie.title} moves back to Watchlist.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Move'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _updatingWatchlist = true);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final previousRate = currentMovie.movieRate;

    try {
      await moviesState.changeMovieRate(
        currentMovie.id,
        MovieRate.addedToWatchlist,
        userState.isIncognitoMode,
        currentMovie,
      );

      if (!userState.isIncognitoMode) {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
          throw const HttpException('Signed-in movie update is unavailable.');
        }

        final response = await ServiceAgent().rateMovie(
          currentMovie.id,
          userId,
          MovieRate.addedToWatchlist,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Movie update failed with ${response.statusCode}.',
          );
        }
      }
    } catch (_) {
      await moviesState.changeMovieRate(
        currentMovie.id,
        previousRate,
        userState.isIncognitoMode,
        currentMovie,
      );
      if (!mounted) {
        return;
      }

      setState(() => _updatingWatchlist = false);
      MSnackBar.showWithMessenger(
        messenger,
        'Couldn’t update ${currentMovie.title}. Try again.',
        false,
        duration: const Duration(milliseconds: 2500),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    navigator.pop();
    MSnackBar.showWithMessenger(
      messenger,
      isViewed ? 'Moved to Watchlist. Rating removed.' : 'Added to Watchlist.',
      true,
      duration: const Duration(milliseconds: 2500),
    );
  }
}

class _PersonalListAction extends StatelessWidget {
  final Movie movie;
  final MoviesList? currentList;

  const _PersonalListAction({
    required this.movie,
    required this.currentList,
  });

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userLists = [...moviesState.personalMoviesLists]
      ..sort((a, b) => a.order.compareTo(b.order));

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
        subtitle: Text(
          currentList == null
              ? 'Choose one of your lists.'
              : 'Add it to another collection.',
          style: const TextStyle(
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
}

class _ListChoice extends StatefulWidget {
  final Movie movie;
  final MoviesList moviesList;

  const _ListChoice({
    required this.movie,
    required this.moviesList,
  });

  @override
  State<_ListChoice> createState() => _ListChoiceState();
}

class _ListChoiceState extends State<_ListChoice> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final movieInList = widget.moviesList.listMovies
        .any((element) => element.id == widget.movie.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: movieInList ? Md3Colors.surfaceMuted : Md3Colors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: movieInList || _submitting ? null : _addToList,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
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
                        widget.moviesList.name,
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
                        '${widget.moviesList.listMovies.length} '
                        'item${widget.moviesList.listMovies.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Md3Colors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_submitting)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
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

  Future<void> _addToList() async {
    if (_submitting) {
      return;
    }

    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    try {
      if (!userState.isIncognitoMode) {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
          throw const HttpException('Signed-in list update is unavailable.');
        }

        final response = await ServiceAgent().addMovieToList(
          userId,
          widget.movie.id,
          widget.moviesList.name,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'List update failed with ${response.statusCode}.',
          );
        }
      }

      moviesState.addMovieToPersonalList(
        widget.moviesList.name,
        widget.movie,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _submitting = false);
      MSnackBar.showWithMessenger(
        messenger,
        'Couldn’t update ${widget.movie.title}. Try again.',
        false,
        duration: const Duration(milliseconds: 2500),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    navigator.pop();
    MSnackBar.showWithMessenger(
      messenger,
      'Added to ${widget.moviesList.name}.',
      true,
      duration: const Duration(milliseconds: 2500),
    );
  }
}

class _RemoveFromListAction extends StatefulWidget {
  final Movie movie;
  final MoviesList moviesList;

  const _RemoveFromListAction({
    required this.movie,
    required this.moviesList,
  });

  @override
  State<_RemoveFromListAction> createState() => _RemoveFromListActionState();
}

class _RemoveFromListActionState extends State<_RemoveFromListAction> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return _SheetActionButton(
      label: 'Remove from ${widget.moviesList.name}',
      detail: 'Keep the movie status, but remove it from this list.',
      icon: Icons.remove_circle_outline_rounded,
      color: Md3Colors.danger,
      busy: _submitting,
      onTap: _submitting ? null : _remove,
    );
  }

  Future<void> _remove() async {
    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    try {
      if (!userState.isIncognitoMode) {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
          throw const HttpException('Signed-in list update is unavailable.');
        }

        final response = await ServiceAgent().removeMovieFromList(
          userId,
          widget.movie.id,
          widget.moviesList.name,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'List update failed with ${response.statusCode}.',
          );
        }
      }

      moviesState.removeMovieFromPersonalList(
        widget.moviesList.name,
        widget.movie,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _submitting = false);
      MSnackBar.showWithMessenger(
        messenger,
        'Couldn’t update ${widget.movie.title}. Try again.',
        false,
        duration: const Duration(milliseconds: 2500),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    navigator.pop();
    MSnackBar.showWithMessenger(
      messenger,
      'Removed from ${widget.moviesList.name}.',
      true,
      duration: const Duration(milliseconds: 2500),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final bool filled;
  final bool busy;
  final VoidCallback? onTap;

  const _SheetActionButton({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.busy = false,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: detailColor,
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: filled ? Colors.white : color,
                  ),
                )
              else
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

class _MetadataPill extends StatelessWidget {
  final String text;

  const _MetadataPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Md3Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Md3Colors.border),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Md3Colors.text,
          fontSize: 12,
          height: 18 / 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
