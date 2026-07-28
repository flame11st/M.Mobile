import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:provider/provider.dart';

Future<void> showMarkWatchedBottomSheet({
  required BuildContext context,
  required Movie movie,
}) {
  return showMd3BottomSheet<void>(
    context: context,
    builder: (context) => MarkWatchedBottomSheet(movie: movie),
  );
}

class MarkWatchedBottomSheet extends StatefulWidget {
  final Movie movie;

  const MarkWatchedBottomSheet({super.key, required this.movie});

  @override
  State<MarkWatchedBottomSheet> createState() => _MarkWatchedBottomSheetState();
}

class _MarkWatchedBottomSheetState extends State<MarkWatchedBottomSheet> {
  final ServiceAgent _serviceAgent = ServiceAgent();
  int? _savingRate;

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
            color: Md3Colors.success,
            busy: _savingRate == MovieRate.liked,
            enabled: _savingRate == null,
            onPressed: () => _rate(MovieRate.liked),
          ),
          const SizedBox(height: 10),
          _OpinionButton(
            label: 'Okay',
            icon: Icons.sentiment_satisfied_alt_rounded,
            color: Md3Colors.warning,
            busy: _savingRate == MovieRate.okay,
            enabled: _savingRate == null,
            onPressed: () => _rate(MovieRate.okay),
          ),
          const SizedBox(height: 10),
          _OpinionButton(
            label: 'Disliked',
            icon: Icons.block_rounded,
            color: Md3Colors.danger,
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

    setState(() => _savingRate = movieRate);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final matchingMovies =
        moviesState.userMovies.where((movie) => movie.id == widget.movie.id);
    final currentMovie =
        matchingMovies.isNotEmpty ? matchingMovies.first : widget.movie;
    final previousRate = currentMovie.movieRate;

    try {
      await moviesState.changeMovieRate(
        currentMovie.id,
        movieRate,
        userState.isIncognitoMode,
        currentMovie,
      );

      if (!userState.isIncognitoMode) {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
          throw const HttpException('Signed-in movie update is unavailable.');
        }

        final response = await _serviceAgent.rateMovie(
          currentMovie.id,
          userId,
          movieRate,
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

      setState(() => _savingRate = null);
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

    final savedAsLabel = MovieRate.opinionLabel(movieRate);
    navigator.pop();
    MSnackBar.showWithMessenger(
      messenger,
      'Moved to Viewed. Saved as $savedAsLabel.',
      true,
      duration: const Duration(milliseconds: 2500),
    );
  }
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, size: 21),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
