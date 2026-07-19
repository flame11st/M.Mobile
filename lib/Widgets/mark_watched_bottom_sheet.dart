import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:provider/provider.dart';

class MarkWatchedBottomSheet extends StatelessWidget {
  final Movie movie;
  final serviceAgent = ServiceAgent();

  MarkWatchedBottomSheet({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Md3Colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was it?',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We will move it to Viewed and save your opinion right away.',
              style: TextStyle(
                color: Md3Colors.muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _opinionButton(
              context,
              'Liked',
              Icons.favorite_rounded,
              Md3Colors.success,
              MovieRate.liked,
            ),
            const SizedBox(height: 10),
            _opinionButton(
              context,
              'Okay',
              Icons.sentiment_satisfied_alt_rounded,
              Md3Colors.warning,
              MovieRate.okay,
            ),
            const SizedBox(height: 10),
            _opinionButton(
              context,
              'Disliked',
              Icons.block_rounded,
              Md3Colors.danger,
              MovieRate.notLiked,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opinionButton(BuildContext context, String label, IconData icon,
      Color color, int movieRate) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _rate(context, movieRate),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Future<void> _rate(BuildContext context, int movieRate) async {
    final navigator = Navigator.of(context);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final savedAsLabel = switch (movieRate) {
      MovieRate.liked => 'Liked',
      MovieRate.okay => 'Okay',
      MovieRate.notLiked => 'Disliked',
      _ => 'Viewed',
    };

    await moviesState.changeMovieRate(
      movie.id,
      movieRate,
      userState.isIncognitoMode,
      movie,
    );

    if (!userState.isIncognitoMode && ServiceAgent.state != null) {
      await serviceAgent.rateMovie(movie.id, userState.userId!, movieRate);
    }

    if (!context.mounted) {
      return;
    }

    navigator.pop();
    MSnackBar.showSnackBar('Moved to Viewed. Saved as $savedAsLabel.', true);
  }
}
