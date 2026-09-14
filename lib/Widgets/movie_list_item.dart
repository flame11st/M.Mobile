import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Services/product_analytics.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/Shared/movie_status_control.dart';
import 'package:mmobile/Widgets/mark_watched_bottom_sheet.dart';
import 'package:mmobile/Widgets/movie_list_item_expanded.dart';
import 'package:mmobile/Widgets/movies_lists_page.dart';
import 'package:provider/provider.dart';

enum MovieCardMode { browse, watchlist, viewed, personalList }

class MovieListItem extends StatelessWidget {
  final Movie movie;
  final MoviesList? moviesList;
  final MoviesList? preferredPersonalList;
  final bool shouldRequestReview;
  final MovieCardMode mode;

  /// Optional contextual metadata below genres, sharing the canonical layout.
  final Widget? supplementaryContent;
  final EdgeInsetsGeometry margin;

  const MovieListItem({
    super.key,
    required this.movie,
    this.moviesList,
    this.preferredPersonalList,
    this.shouldRequestReview = false,
    this.mode = MovieCardMode.browse,
    this.supplementaryContent,
    this.margin = const EdgeInsets.symmetric(
      horizontal: Md3Spacing.x12,
      vertical: 6,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final matchingMovies = moviesState.userMovies.where(
      (element) => element.id == movie.id,
    );
    final currentMovie = matchingMovies.isNotEmpty
        ? matchingMovies.first
        : movie;
    final mediaQuery = MediaQuery.of(context);
    final isCompactPoster = mediaQuery.size.width <= 390;
    final posterWidth = isCompactPoster ? 72.0 : 80.0;
    final posterHeight = isCompactPoster ? 108.0 : 120.0;
    final isWatchlist = mode == MovieCardMode.watchlist;

    return Hero(
      tag: 'movie-hero-animation${movie.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: Md3Colors.surface,
            borderRadius: BorderRadius.circular(Md3Radius.card),
            border: Border.all(color: Md3Colors.border),
            boxShadow: Md3Shadows.contentCard,
          ),
          child: Material(
            key: ValueKey('movie-card-surface-${movie.id}'),
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Md3Radius.card),
            clipBehavior: Clip.antiAlias,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              button: true,
              label: 'Open ${currentMovie.title} details',
              onTap: () => _openDetails(context, currentMovie),
              child: InkWell(
                key: ValueKey('movie-card-details-action-${movie.id}'),
                excludeFromSemantics: true,
                borderRadius: BorderRadius.circular(Md3Radius.card),
                onTap: () => _openDetails(context, currentMovie),
                child: Padding(
                  padding: const EdgeInsets.all(Md3Spacing.x12),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: posterWidth,
                          child: Align(
                            alignment: Alignment.center,
                            child: Md3MoviePoster(
                              movie: currentMovie,
                              width: posterWidth,
                              height: posterHeight,
                              borderRadius: Md3Radius.poster,
                            ),
                          ),
                        ),
                        const SizedBox(width: Md3Spacing.x12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: _MovieCardContent(
                              movie: currentMovie,
                              supplementaryContent: supplementaryContent,
                              trailingAction: isWatchlist
                                  ? KeyedSubtree(
                                      key: ValueKey(
                                        'movie-card-trailing-action-${movie.id}',
                                      ),
                                      child: _MarkWatchedButton(
                                        key: const Key(
                                          'movie-card-mark-watched-action',
                                        ),
                                        movie: currentMovie,
                                        onPressed: () => _openMarkWatchedSheet(
                                          context,
                                          currentMovie,
                                        ),
                                      ),
                                    )
                                  : MovieStatusControl(
                                      key: ValueKey(
                                        'movie-card-trailing-action-${movie.id}',
                                      ),
                                      movie: currentMovie,
                                      onPressed: () => _openActionsSheet(
                                        context,
                                        currentMovie,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

  Future<int?> _openMarkWatchedSheet(BuildContext context, Movie currentMovie) {
    return showMarkWatchedBottomSheet(context: context, movie: currentMovie);
  }

  Future<void> _openActionsSheet(BuildContext context, Movie currentMovie) {
    return showMd3BottomSheet<void>(
      context: context,
      builder: (sheetContext) => _MovieRowActionsSheet(
        movie: currentMovie,
        moviesList: moviesList,
        preferredPersonalList: preferredPersonalList,
        mode: mode,
        shouldRequestReview: shouldRequestReview,
        parentContext: context,
      ),
    );
  }
}

class _MovieCardContent extends StatelessWidget {
  final Movie movie;
  final Widget trailingAction;
  final Widget? supplementaryContent;

  const _MovieCardContent({
    required this.movie,
    required this.trailingAction,
    this.supplementaryContent,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
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
                  if (supplementaryContent != null) ...[
                    const SizedBox(height: Md3Spacing.x4),
                    supplementaryContent!,
                  ],
                ],
              ),
            ),
            const SizedBox(width: Md3Spacing.x8),
            trailingAction,
          ],
        ),
      ],
    );
  }
}

class _MarkWatchedButton extends StatefulWidget {
  final Movie movie;
  final Future<int?> Function() onPressed;

  const _MarkWatchedButton({
    super.key,
    required this.movie,
    required this.onPressed,
  });

  @override
  State<_MarkWatchedButton> createState() => _MarkWatchedButtonState();
}

class _MarkWatchedButtonState extends State<_MarkWatchedButton> {
  bool _opening = false;
  final _hintKey = GlobalKey<TooltipState>();
  Timer? _hintTimer;

  bool get _canShowHint {
    if (!mounted ||
        _opening ||
        !TickerMode.valuesOf(context).enabled ||
        ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final media = MediaQuery.of(context);
    // Wait for an anchor with enough space above; never flip this hint below.
    return center.dy > media.padding.top + 60 &&
        center.dy < media.size.height - media.padding.bottom &&
        center.dx > 0 &&
        center.dx < media.size.width &&
        !context.read<MoviesState>().isMovieMutationActive(widget.movie.id);
  }

  void _scheduleHint() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_canShowHint) return;
      unawaited(
        context.read<UserState>().showMarkWatchedHintOnce(() {
          if (!_canShowHint) return false;
          final shown = _hintKey.currentState?.ensureTooltipVisible() ?? false;
          if (shown) {
            _hintTimer = Timer(
              const Duration(seconds: 4),
              Tooltip.dismissAllToolTips,
            );
          }
          return shown;
        }),
      );
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    Tooltip.dismissAllToolTips();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    Tooltip.dismissAllToolTips();
    setState(() => _opening = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleHint();
    final pending = context.watch<MoviesState>().isMovieMutationActive(
      widget.movie.id,
    );
    final enabled = !pending && !_opening;
    return SizedBox(
      width: 44,
      height: 44,
      child: Semantics(
        container: true,
        sortKey: const OrdinalSortKey(1),
        button: true,
        enabled: enabled,
        label: 'Mark watched',
        hint: 'Rate ${widget.movie.title}: Liked, Okay, or Disliked',
        onTap: enabled ? _open : null,
        child: ExcludeSemantics(
          child: Tooltip(
            key: _hintKey,
            message: 'Mark watched',
            preferBelow: false,
            verticalOffset: 30,
            triggerMode: TooltipTriggerMode.manual,
            showDuration: const Duration(seconds: 4),
            ignorePointer: true,
            child: IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                maximumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                backgroundColor: Md3Colors.primarySoft,
                foregroundColor: Md3Colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: enabled ? _open : null,
              icon: pending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _MovieRowActionsSheet extends StatefulWidget {
  final Movie movie;
  final MoviesList? moviesList;
  final MoviesList? preferredPersonalList;
  final MovieCardMode mode;
  final bool shouldRequestReview;
  final BuildContext parentContext;

  const _MovieRowActionsSheet({
    required this.movie,
    required this.moviesList,
    required this.preferredPersonalList,
    required this.mode,
    required this.shouldRequestReview,
    required this.parentContext,
  });

  @override
  State<_MovieRowActionsSheet> createState() => _MovieRowActionsSheetState();
}

class _MovieRowActionsSheetState extends State<_MovieRowActionsSheet> {
  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final matchingMovies = moviesState.userMovies.where(
      (element) => element.id == widget.movie.id,
    );
    final currentMovie = matchingMovies.isNotEmpty
        ? matchingMovies.first
        : widget.movie;

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
          const SizedBox(height: 16),
          MovieStatusSelector(
            movie: currentMovie,
            shouldRequestReview: widget.shouldRequestReview,
          ),
          const SizedBox(height: 16),
          _PersonalListAction(
            movie: currentMovie,
            currentList: widget.moviesList,
            preferredList: widget.preferredPersonalList,
          ),
          const SizedBox(height: 12),
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
}

class _PersonalListAction extends StatelessWidget {
  final Movie movie;
  final MoviesList? currentList;
  final MoviesList? preferredList;

  const _PersonalListAction({
    required this.movie,
    required this.currentList,
    required this.preferredList,
  });

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userLists = [...moviesState.personalMoviesLists]
      ..sort((a, b) => a.order.compareTo(b.order));
    final livePreferredList = preferredList == null
        ? null
        : userLists.cast<MoviesList?>().firstWhere(
            (list) => identical(list, preferredList),
            orElse: () => null,
          );

    if (preferredList != null && livePreferredList == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OriginListUnavailableNotice(listName: preferredList!.name),
          const SizedBox(height: 12),
          if (userLists.isEmpty)
            _buildCreateListAction(context)
          else ...[
            const Text(
              'Choose another personal list',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (final list in userLists)
              _ListChoice(movie: movie, moviesList: list),
          ],
        ],
      );
    }

    if (userLists.isEmpty) {
      return _buildCreateListAction(context);
    }

    if (livePreferredList != null) {
      final otherLists = userLists
          .where((list) => !identical(list, livePreferredList))
          .toList(growable: false);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ListChoice(
            movie: movie,
            moviesList: livePreferredList,
            preferred: true,
          ),
          if (otherLists.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  leading: const _SheetActionIcon(
                    icon: Icons.playlist_add_rounded,
                    color: Md3Colors.muted,
                  ),
                  title: const Text(
                    'Choose another personal list',
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: const Text(
                    'Keep this Search open and pick a different collection.',
                    style: TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    for (final list in otherLists)
                      _ListChoice(movie: movie, moviesList: list),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.transparent,
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
      ),
    );
  }

  Widget _buildCreateListAction(BuildContext context) {
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
}

class _OriginListUnavailableNotice extends StatelessWidget {
  final String listName;

  const _OriginListUnavailableNotice({required this.listName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Md3Colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Md3Colors.warning.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Md3Colors.warning,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '“$listName” changed or is no longer available. '
              'Choose another list.',
              style: const TextStyle(
                color: Md3Colors.text,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListChoice extends StatefulWidget {
  final Movie movie;
  final MoviesList moviesList;
  final bool preferred;

  const _ListChoice({
    required this.movie,
    required this.moviesList,
    this.preferred = false,
  });

  @override
  State<_ListChoice> createState() => _ListChoiceState();
}

class _ListChoiceState extends State<_ListChoice> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final movieInList = widget.moviesList.listMovies.any(
      (element) => element.id == widget.movie.id,
    );
    final title = widget.preferred
        ? movieInList
              ? 'Added to ${widget.moviesList.name}'
              : 'Add to ${widget.moviesList.name}'
        : widget.moviesList.name;
    final detail = widget.preferred
        ? movieInList
              ? 'Already in your open personal list.'
              : 'Your open personal list.'
        : '${widget.moviesList.listMovies.length} '
              'item${widget.moviesList.listMovies.length == 1 ? '' : 's'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: widget.preferred
            ? Md3Colors.primarySoft
            : movieInList
            ? Md3Colors.surfaceMuted
            : Md3Colors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: movieInList || _submitting ? null : _addToList,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.preferred
                    ? Md3Colors.primary.withValues(alpha: 0.35)
                    : Md3Colors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
                        detail,
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

      moviesState.addMovieToPersonalList(widget.moviesList.name, widget.movie);
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

    unawaited(
      ProductAnalytics.instance.track(
        ProductAnalyticsEventName.personalListItemAdded,
        parameters: {
          ProductAnalyticsParameter.movieId: widget.movie.id,
          ProductAnalyticsParameter.sourceSurface: 'movie_actions',
        },
      ),
    );
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

  const _RemoveFromListAction({required this.movie, required this.moviesList});

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
      color: Md3Colors.destructive,
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
  final bool filled = false;
  final bool busy;
  final VoidCallback? onTap;

  const _SheetActionButton({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final background = filled ? color : Md3Colors.background;
    final foreground = filled ? Colors.white : Md3Colors.text;
    final detailColor = filled
        ? Colors.white.withValues(alpha: 0.82)
        : Md3Colors.muted;

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
                      maxLines: isLargeText ? 4 : 2,
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
                      maxLines: isLargeText ? 6 : 3,
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
        borderRadius: BorderRadius.circular(Md3Radius.pill),
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
