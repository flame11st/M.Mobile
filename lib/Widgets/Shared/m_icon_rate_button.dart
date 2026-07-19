import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/m_icon_button.dart';
import 'package:provider/provider.dart';
import 'm_snack_bar.dart';

class MIconRateButton extends StatelessWidget {
  final icon;
  final serviceAgent = ServiceAgent();
  final width;
  final color;
  final bool fromSearch;
  final bool closeParentOnRate;
  final String? hint;
  final Movie movie;
  final int movieRate;
  final bool shouldRequestReview;

  MIconRateButton(
      {this.icon,
      this.width,
      this.color,
      this.fromSearch = false,
      this.closeParentOnRate = true,
      this.shouldRequestReview = false,
      this.hint,
      required this.movie,
      required this.movieRate});

  rateMovie(String movieId, int movieRate, MoviesState moviesState,
      UserState userState) async {
    moviesState.changeMovieRate(
        movieId, movieRate, userState.isIncognitoMode, movie);

    if (!userState.isIncognitoMode) {
      if (ServiceAgent.state != null) {
        await serviceAgent.rateMovie(movieId, userState.userId!, movieRate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);
    final movies =
        moviesState.userMovies.where((element) => element.id == movie.id);
    final previousMovieRate =
        movies.isNotEmpty ? movies.first.movieRate : MovieRate.notRated;
    final text = _buildStatusMessage(previousMovieRate, movieRate);

    return MIconButton(
      width: width,
      icon: icon,
      color: color,
      hint: hint,
      onPressedCallback: () async {
        final navigator = Navigator.of(context);

        await rateMovie(movie.id, movieRate, moviesState, userState);

        if (closeParentOnRate && navigator.canPop()) {
          navigator.pop();
        }

        if (fromSearch && navigator.canPop()) {
          navigator.pop();
        }

        if (shouldRequestReview || fromSearch) {
          userState.shouldRequestReview = true;
        }

        await Future.delayed(const Duration(milliseconds: 300));

        MSnackBar.showSnackBar(text, true);
      },
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
