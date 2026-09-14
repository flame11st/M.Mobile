import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Services/product_analytics.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:provider/provider.dart';

Future<int?> showMarkWatchedBottomSheet({
  required BuildContext context,
  required Movie movie,
  String sourceSurface = 'watchlist',
  String? recommendationSessionId,
  ServiceAgent? serviceAgent,
}) {
  final originIsRootRoute = ModalRoute.of(context)?.isFirst ?? false;
  unawaited(
    ProductAnalytics.instance.track(
      ProductAnalyticsEventName.markWatchedStarted,
      parameters: {
        ProductAnalyticsParameter.movieId: movie.id,
        ProductAnalyticsParameter.sourceSurface: sourceSurface,
        if (recommendationSessionId != null)
          ProductAnalyticsParameter.recommendationSessionId:
              recommendationSessionId,
      },
    ),
  );
  return showMd3BottomSheet<int>(
    context: context,
    builder: (context) => MarkWatchedBottomSheet(
      movie: movie,
      sourceSurface: sourceSurface,
      recommendationSessionId: recommendationSessionId,
      serviceAgent: serviceAgent,
      originIsRootRoute: originIsRootRoute,
    ),
  );
}

class MarkWatchedBottomSheet extends StatefulWidget {
  final Movie movie;
  final String sourceSurface;
  final String? recommendationSessionId;
  final ServiceAgent? serviceAgent;
  final bool originIsRootRoute;

  const MarkWatchedBottomSheet({
    super.key,
    required this.movie,
    this.sourceSurface = 'watchlist',
    this.recommendationSessionId,
    this.serviceAgent,
    required this.originIsRootRoute,
  });

  @override
  State<MarkWatchedBottomSheet> createState() => _MarkWatchedBottomSheetState();
}

class _MarkWatchedBottomSheetState extends State<MarkWatchedBottomSheet> {
  static const _mutationTimeout = Duration(seconds: 12);

  late final ServiceAgent _serviceAgent;
  int? _savingRate;

  @override
  void initState() {
    super.initState();
    _serviceAgent = widget.serviceAgent ?? ServiceAgent();
  }

  @override
  Widget build(BuildContext context) {
    return Md3BottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How was it?',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 24,
              height: 29 / 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Move to Viewed and save your opinion.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Md3Colors.muted,
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _OpinionButton(
            label: 'Liked',
            icon: Icons.favorite_rounded,
            color: Md3Colors.liked,
            busy: _savingRate == MovieRate.liked,
            enabled: _savingRate == null,
            onPressed: () => _rate(MovieRate.liked),
          ),
          const SizedBox(height: 10),
          _OpinionButton(
            label: 'Okay',
            icon: Icons.sentiment_satisfied_alt_rounded,
            color: Md3Colors.okay,
            busy: _savingRate == MovieRate.okay,
            enabled: _savingRate == null,
            onPressed: () => _rate(MovieRate.okay),
          ),
          const SizedBox(height: 10),
          _OpinionButton(
            label: 'Disliked',
            icon: Icons.block_rounded,
            color: Md3Colors.disliked,
            busy: _savingRate == MovieRate.notLiked,
            enabled: _savingRate == null,
            onPressed: () => _rate(MovieRate.notLiked),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Md3Colors.primary,
                minimumSize: const Size(44, 44),
              ),
              onPressed: _savingRate == null
                  ? () => Navigator.of(context).pop()
                  : null,
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rate(int movieRate) async {
    if (_savingRate != null) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final matchingMovies = moviesState.userMovies.where(
      (movie) => movie.id == widget.movie.id,
    );
    final currentMovie = matchingMovies.isNotEmpty
        ? matchingMovies.first
        : widget.movie;
    final snapshot = moviesState.captureMovieState(
      currentMovie.id,
      currentMovie,
    );

    if (!moviesState.beginMovieMutation(currentMovie.id)) {
      MSnackBar.showWithMessenger(
        messenger,
        '${currentMovie.title} is already being updated.',
        false,
      );
      return;
    }

    setState(() => _savingRate = movieRate);
    var didSave = false;
    var savedRevision = moviesState.movieMutationRevision(currentMovie.id);

    try {
      await moviesState.changeMovieRate(
        currentMovie.id,
        movieRate,
        userState.isIncognitoMode,
        currentMovie,
        persistImmediately: true,
        awaitAnonymousSyncPersistence: true,
        commitRatingState: false,
      );

      if (!userState.isIncognitoMode) {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
          throw const HttpException('Signed-in movie update is unavailable.');
        }

        final response = await _serviceAgent
            .rateMovie(currentMovie.id, userId, movieRate)
            .timeout(_mutationTimeout);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Movie update failed with ${response.statusCode}.',
          );
        }
      }
      moviesState.commitRatingStateMutation();
      savedRevision = moviesState.movieMutationRevision(currentMovie.id);
      didSave = true;
    } catch (_) {
      await moviesState.restoreMovieState(
        snapshot,
        userState.isIncognitoMode,
        currentMovie,
        commitRatingState: false,
      );
      widget.movie.movieRate = snapshot.movieRate;
      widget.movie.updated = snapshot.updated;

      if (!mounted) {
        return;
      }

      setState(() => _savingRate = null);
      MSnackBar.showWithMessenger(
        messenger,
        'Couldn’t update ${currentMovie.title}. Try again.',
        false,
        duration: const Duration(milliseconds: 2500),
      );
      return;
    } finally {
      moviesState.endMovieMutation(currentMovie.id);
    }

    if (!didSave || !mounted) {
      return;
    }

    unawaited(
      trackMovieStateTransition(
        movieId: currentMovie.id,
        previousRate: snapshot.movieRate,
        nextRate: movieRate,
        sourceSurface: widget.sourceSurface,
      ),
    );
    unawaited(
      ProductAnalytics.instance.track(
        ProductAnalyticsEventName.markWatchedCompleted,
        parameters: {
          ProductAnalyticsParameter.movieId: currentMovie.id,
          ProductAnalyticsParameter.opinionState: MovieRate.opinionLabel(
            movieRate,
          ).toLowerCase(),
          ProductAnalyticsParameter.sourceSurface: widget.sourceSurface,
          if (widget.recommendationSessionId != null)
            ProductAnalyticsParameter.recommendationSessionId:
                widget.recommendationSessionId,
        },
      ),
    );
    if (widget.sourceSurface == 'recommendations') {
      unawaited(
        ProductAnalytics.instance.track(
          ProductAnalyticsEventName.recommendationSeenAlready,
          parameters: {
            ProductAnalyticsParameter.movieId: currentMovie.id,
            ProductAnalyticsParameter.opinionState: MovieRate.opinionLabel(
              movieRate,
            ).toLowerCase(),
            ProductAnalyticsParameter.sourceSurface: 'recommendations',
            if (widget.recommendationSessionId != null)
              ProductAnalyticsParameter.recommendationSessionId:
                  widget.recommendationSessionId,
          },
          transitionId: widget.recommendationSessionId == null
              ? null
              : '${widget.recommendationSessionId}:${currentMovie.id}',
        ),
      );
    }

    final savedAsLabel = MovieRate.opinionLabel(movieRate);
    final sourceSurface = widget.sourceSurface;
    final visibleMovie = widget.movie;
    navigator.pop(movieRate);
    MSnackBar.showWithMessenger(
      messenger,
      'Rated $savedAsLabel · Moved to Viewed',
      true,
      duration: MSnackBar.actionDuration,
      bottomMargin: widget.originIsRootRoute
          ? MSnackBar.aboveRootNavigation(messenger.context)
          : MSnackBar.actionBottomMargin,
      actionLabel: 'Undo',
      feedbackIcon: switch (movieRate) {
        MovieRate.liked => Icons.favorite_rounded,
        MovieRate.okay => Icons.sentiment_satisfied_alt_rounded,
        _ => Icons.thumb_down_alt_rounded,
      },
      feedbackIconColor: switch (movieRate) {
        MovieRate.liked => Md3Colors.liked,
        MovieRate.okay => Md3Colors.okay,
        _ => Md3Colors.disliked,
      },
      feedbackIconBackgroundColor: switch (movieRate) {
        MovieRate.liked => Md3Colors.likedSoft,
        MovieRate.okay => Md3Colors.okaySoft,
        _ => Md3Colors.dislikedSoft,
      },
      onAction: () => unawaited(
        _undoMarkWatched(
          moviesState: moviesState,
          userState: userState,
          serviceAgent: _serviceAgent,
          messenger: messenger,
          movie: currentMovie,
          visibleMovie: visibleMovie,
          snapshot: snapshot,
          savedRate: movieRate,
          savedRevision: savedRevision,
          sourceSurface: sourceSurface,
        ),
      ),
    );
  }
}

Future<void> _undoMarkWatched({
  required MoviesState moviesState,
  required UserState userState,
  required ServiceAgent serviceAgent,
  required ScaffoldMessengerState messenger,
  required Movie movie,
  required Movie visibleMovie,
  required MovieStateSnapshot snapshot,
  required int savedRate,
  required int savedRevision,
  required String sourceSurface,
}) async {
  if (!moviesState.beginMovieMutation(movie.id)) {
    MSnackBar.showWithMessenger(
      messenger,
      '${movie.title} is already being updated. The saved rating was kept.',
      false,
    );
    return;
  }

  var didUndo = false;
  try {
    final matchingMovies = moviesState.userMovies.where(
      (item) => item.id == movie.id,
    );
    final currentMovie = matchingMovies.isEmpty ? movie : matchingMovies.first;
    if (moviesState.movieMutationRevision(movie.id) != savedRevision ||
        currentMovie.movieRate != savedRate) {
      MSnackBar.showWithMessenger(
        messenger,
        '${movie.title} changed after Mark Watched. Its current state was kept.',
        false,
      );
      return;
    }

    await moviesState.restoreMovieState(
      snapshot,
      userState.isIncognitoMode,
      currentMovie,
      commitRatingState: false,
    );
    visibleMovie.movieRate = snapshot.movieRate;
    visibleMovie.updated = snapshot.updated;

    if (!userState.isIncognitoMode) {
      final userId = userState.userId;
      if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
        throw const HttpException('Signed-in movie update is unavailable.');
      }

      final response = await serviceAgent
          .rateMovie(movie.id, userId, snapshot.movieRate)
          .timeout(_MarkWatchedBottomSheetState._mutationTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Movie update failed with ${response.statusCode}.');
      }
    }

    moviesState.commitRatingStateMutation();
    didUndo = true;
  } catch (_) {
    await moviesState.changeMovieRate(
      movie.id,
      savedRate,
      userState.isIncognitoMode,
      movie,
      persistImmediately: true,
      awaitAnonymousSyncPersistence: true,
      commitRatingState: false,
    );
    visibleMovie.movieRate = savedRate;
    MSnackBar.showWithMessenger(
      messenger,
      'Couldn’t undo. ${movie.title} remains in Viewed as ${MovieRate.opinionLabel(savedRate)}.',
      false,
    );
  } finally {
    moviesState.endMovieMutation(movie.id);
  }

  if (!didUndo) {
    return;
  }

  unawaited(
    trackMovieStateTransition(
      movieId: movie.id,
      previousRate: savedRate,
      nextRate: snapshot.movieRate,
      sourceSurface: sourceSurface,
    ),
  );
  final restoredLabel = snapshot.movieRate == MovieRate.addedToWatchlist
      ? 'Restored to Watchlist.'
      : snapshot.movieRate == MovieRate.notRated
      ? 'Removed the rating.'
      : 'Restored as ${MovieRate.opinionLabel(snapshot.movieRate)}.';
  MSnackBar.showWithMessenger(
    messenger,
    'Undo complete · $restoredLabel',
    true,
    duration: const Duration(milliseconds: 2200),
  );
}

class _OpinionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  const _OpinionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          disabledBackgroundColor: color.withValues(alpha: 0.06),
          foregroundColor: color,
          disabledForegroundColor: color.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withValues(alpha: 0.18)),
          ),
        ),
        onPressed: enabled ? onPressed : null,
        icon: busy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 21),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
