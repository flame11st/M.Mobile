import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/product_analytics.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/m_dialog.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:provider/provider.dart';

/// Shared by the compact card and its first-sheet status selector.
class MovieStatusPresentation {
  final String label;
  final IconData icon;
  final Color color;

  const MovieStatusPresentation(this.label, this.icon, this.color);

  static MovieStatusPresentation forRate(int rate) => switch (rate) {
    MovieRate.addedToWatchlist => const MovieStatusPresentation(
      'In Watchlist',
      Icons.bookmark_rounded,
      Md3Colors.primary,
    ),
    MovieRate.liked => const MovieStatusPresentation(
      'Liked',
      Icons.favorite_rounded,
      Md3Colors.liked,
    ),
    MovieRate.okay => const MovieStatusPresentation(
      'Rated Okay',
      Icons.sentiment_satisfied_alt_rounded,
      Md3Colors.okay,
    ),
    MovieRate.notLiked => const MovieStatusPresentation(
      'Disliked',
      Icons.block_rounded,
      Md3Colors.disliked,
    ),
    _ => const MovieStatusPresentation(
      'No status',
      Icons.add_rounded,
      Md3Colors.primary,
    ),
  };
}

class MovieStatusControl extends StatefulWidget {
  final Movie movie;
  final Future<void> Function() onPressed;
  const MovieStatusControl({
    super.key,
    required this.movie,
    required this.onPressed,
  });

  @override
  State<MovieStatusControl> createState() => _MovieStatusControlState();
}

class _MovieStatusControlState extends State<MovieStatusControl> {
  bool _opening = false;
  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = MovieStatusPresentation.forRate(widget.movie.movieRate);
    final pending = context.watch<MoviesState>().isMovieMutationActive(
      widget.movie.id,
    );
    final label = 'Movie actions. ${status.label}. ${widget.movie.title}';
    return SizedBox(
      width: 44,
      height: 44,
      child: Semantics(
        container: true,
        sortKey: const OrdinalSortKey(1),
        button: true,
        enabled: !pending && !_opening,
        label: label,
        onTap: pending || _opening ? null : _open,
        child: ExcludeSemantics(
          child: IconButton(
            tooltip: label,
            onPressed: pending || _opening ? null : _open,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              maximumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              backgroundColor: status.color.withValues(alpha: 0.08),
              foregroundColor: status.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: pending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: status.color,
                    ),
                  )
                : Icon(status.icon, size: 21),
          ),
        ),
      ),
    );
  }
}

class MovieStatusSelector extends StatefulWidget {
  final Movie movie;
  final bool shouldRequestReview;
  const MovieStatusSelector({
    super.key,
    required this.movie,
    this.shouldRequestReview = false,
  });

  @override
  State<MovieStatusSelector> createState() => _MovieStatusSelectorState();
}

class _MovieStatusSelectorState extends State<MovieStatusSelector> {
  bool _busy = false;
  Movie get _current {
    final copies = context.read<MoviesState>().userMovies.where(
      (m) => m.id == widget.movie.id,
    );
    return copies.isEmpty ? widget.movie : copies.first;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MoviesState>();
    final current = _current;
    final pending =
        _busy || context.read<MoviesState>().isMovieMutationActive(current.id);
    const rates = [
      MovieRate.liked,
      MovieRate.okay,
      MovieRate.notLiked,
      MovieRate.addedToWatchlist,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            color: Md3Colors.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaQuery.textScalerOf(context).scale(1) > 1.1
                ? 2
                : 4;
            final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rate in rates)
                  SizedBox(
                    width: width,
                    child: _tile(rate, current.movieRate == rate, pending),
                  ),
              ],
            );
          },
        ),
        if (current.movieRate != MovieRate.notRated) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: pending ? null : () => _select(MovieRate.notRated),
            style: TextButton.styleFrom(
              foregroundColor: Md3Colors.destructive,
              minimumSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
            label: Text(
              MovieRate.isViewed(current.movieRate)
                  ? 'Remove from Viewed'
                  : 'Remove from Watchlist',
            ),
          ),
        ],
      ],
    );
  }

  Widget _tile(int rate, bool selected, bool pending) {
    final status = MovieStatusPresentation.forRate(rate);
    final label = MovieRate.opinionLabel(rate);
    return Semantics(
      key: ValueKey('movie-status-${label.toLowerCase()}'),
      button: true,
      selected: selected,
      enabled: !pending,
      label: '$label status',
      excludeSemantics: true,
      onTap: pending ? null : () => _select(rate),
      child: OutlinedButton(
        onPressed: pending ? null : () => _select(rate),
        style: OutlinedButton.styleFrom(
          foregroundColor: status.color,
          backgroundColor: selected
              ? status.color.withValues(alpha: 0.1)
              : Md3Colors.surface,
          side: BorderSide(
            color: selected ? status.color : Md3Colors.border,
            width: selected ? 1.5 : 1,
          ),
          minimumSize: const Size(44, 76),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(int rate) async {
    if (_busy) return;
    final current = _current;
    if (rate == current.movieRate) {
      return; // Repeated selection is never removal.
    }
    setState(() => _busy = true);
    if (MovieRate.isViewed(current.movieRate) &&
        (rate == MovieRate.addedToWatchlist || rate == MovieRate.notRated)) {
      final toWatchlist = rate == MovieRate.addedToWatchlist;
      final confirmed = await showMd3ConfirmationDialog(
        context: context,
        title: toWatchlist ? 'Move to Watchlist?' : 'Remove from Viewed?',
        body:
            'Your ${MovieRate.opinionLabel(current.movieRate)} rating will be removed '
            'when ${current.title} ${toWatchlist ? 'moves back to Watchlist' : 'is removed from Viewed'}.',
        confirmLabel: toWatchlist ? 'Move to Watchlist' : 'Remove rating',
        onConfirm: () {},
      );
      if (!mounted) return;
      if (!confirmed) {
        setState(() => _busy = false);
        return;
      }
    }
    final movies = context.read<MoviesState>();
    final user = context.read<UserState>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!movies.beginMovieMutation(current.id)) {
      setState(() => _busy = false);
      return;
    }
    final snapshot = movies.captureMovieState(current.id, current);
    try {
      await movies.changeMovieRate(
        current.id,
        rate,
        user.isIncognitoMode,
        current,
        persistImmediately: true,
        awaitAnonymousSyncPersistence: true,
        commitRatingState: false,
      );
      await _persist(user, current.id, rate);
      movies.commitRatingStateMutation();
    } catch (_) {
      await movies.restoreMovieState(
        snapshot,
        user.isIncognitoMode,
        current,
        commitRatingState: false,
      );
      widget.movie.movieRate = snapshot.movieRate;
      widget.movie.updated = snapshot.updated;
      MSnackBar.showWithMessenger(
        messenger,
        'Couldn’t update ${current.title}. Try again.',
        false,
      );
      if (mounted) setState(() => _busy = false);
      return;
    } finally {
      movies.endMovieMutation(current.id);
    }
    widget.movie.movieRate = rate;
    if (widget.shouldRequestReview) {
      user.shouldRequestReview = true;
    }
    final revision = movies.movieMutationRevision(current.id);
    unawaited(
      trackMovieStateTransition(
        movieId: current.id,
        previousRate: snapshot.movieRate,
        nextRate: rate,
        sourceSurface: 'movie_actions',
      ),
    );
    if (mounted) navigator.pop();
    MSnackBar.showWithMessenger(
      messenger,
      rate == MovieRate.notRated
          ? 'Removed from My Movies'
          : rate == MovieRate.addedToWatchlist
          ? (MovieRate.isViewed(snapshot.movieRate)
                ? 'Moved to Watchlist · Rating removed'
                : 'Saved to Watchlist')
          : 'Rated ${MovieRate.opinionLabel(rate)} · Saved to Viewed',
      true,
      duration: MSnackBar.actionDuration,
      bottomMargin: MSnackBar.actionBottomMargin,
      actionLabel: 'Undo',
      onAction: () => unawaited(
        _undo(movies, user, messenger, current, snapshot, rate, revision),
      ),
    );
  }

  Future<void> _persist(UserState user, String id, int rate) async {
    if (user.isIncognitoMode) return;
    final userId = user.userId;
    if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
      throw const HttpException('Signed-in movie update is unavailable.');
    }
    final response = await ServiceAgent()
        .rateMovie(id, userId, rate)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Movie update failed with ${response.statusCode}.');
    }
  }

  Future<void> _undo(
    MoviesState movies,
    UserState user,
    ScaffoldMessengerState messenger,
    Movie movie,
    MovieStateSnapshot snapshot,
    int savedRate,
    int revision,
  ) async {
    if (!movies.beginMovieMutation(movie.id)) return;
    final savedSnapshot = movies.captureMovieState(movie.id, movie);
    try {
      if (movies.movieMutationRevision(movie.id) != revision ||
          savedSnapshot.movieRate != savedRate) {
        MSnackBar.showWithMessenger(
          messenger,
          '${movie.title} changed again. Its current state was kept.',
          false,
        );
        return;
      }
      await movies.restoreMovieState(
        snapshot,
        user.isIncognitoMode,
        movie,
        commitRatingState: false,
      );
      await _persist(user, movie.id, snapshot.movieRate);
      movies.commitRatingStateMutation();
      widget.movie.movieRate = snapshot.movieRate;
      widget.movie.updated = snapshot.updated;
    } catch (_) {
      await movies.restoreMovieState(
        savedSnapshot,
        user.isIncognitoMode,
        movie,
        commitRatingState: false,
      );
      widget.movie.movieRate = savedRate;
      MSnackBar.showWithMessenger(
        messenger,
        'Couldn’t undo. The saved status was kept.',
        false,
      );
      return;
    } finally {
      movies.endMovieMutation(movie.id);
    }
    unawaited(
      trackMovieStateTransition(
        movieId: movie.id,
        previousRate: savedRate,
        nextRate: snapshot.movieRate,
        sourceSurface: 'movie_actions',
      ),
    );
    MSnackBar.showWithMessenger(
      messenger,
      'Undo complete · Previous status restored',
      true,
    );
  }
}
