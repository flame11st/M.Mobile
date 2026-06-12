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
  final String? hint;
  final Movie movie;
  final int movieRate;
  final bool shouldRequestReview;

  MIconRateButton(
      {this.icon,
      this.width,
      this.color,
      this.fromSearch = false,
      this.shouldRequestReview = false,
      this.hint,
      required this.movie,
      required this.movieRate});

  rateMovie(String movieId, int movieRate, MoviesState moviesState,
      UserState userState) async {
    moviesState.changeMovieRate(movieId, movieRate, userState.isIncognitoMode, movie);

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
    var action = 'added';
    var isViewedMovie = false;

    final movies =
        moviesState.userMovies.where((element) => element.id == movie.id);

    if (movies.isNotEmpty) {
      action = 'moved';

      if (movies.first.movieRate == MovieRate.liked ||
          movies.first.movieRate == MovieRate.notLiked) isViewedMovie = true;
    }

    var text = '"${movie.title}" $action to your Watchlist!';

    if (movieRate == MovieRate.notRated) {
      text = '"${movie.title}" removed from your movies!';
    }

    if (movieRate == MovieRate.liked || movieRate == MovieRate.notLiked) {
      if (isViewedMovie) {
        text = '"${movie.title}" rate changed!';
      } else {
        text = '"${movie.title}" $action to your viewed movies!';
      }
    }

    return MIconButton(
      width: width,
      icon: icon,
      color: color,
      hint: hint,
      onPressedCallback: () async {
        Navigator.of(context).pop();

        if (fromSearch) {
          Navigator.of(context).pop();
        }

        if (shouldRequestReview || fromSearch) {
          userState.shouldRequestReview = true;
        }

        await Future.delayed(const Duration(milliseconds: 300));

        MSnackBar.showSnackBar(text, true);

        await Future.delayed(const Duration(milliseconds: 300));

        rateMovie(movie.id, movieRate, moviesState, userState);
      },
    );
  }
}

