import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Widgets/Providers/MoviesState.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/MIconButton.dart';
import 'package:provider/provider.dart';
import 'MSnackBar.dart';

class MIconRateButton extends StatelessWidget {
  final icon;
  final int movieRate;
  final String movieId;
  final serviceAgent = new ServiceAgent();
  final width;

  MIconRateButton({this.icon, this.movieRate, this.movieId, this.width});

  rateMovie(String movieId, int movieRate, MoviesState moviesState,
      UserState userState) async {
    moviesState.changeMovieRate(movieId, movieRate);

    serviceAgent.state = userState;
    await serviceAgent.rateMovie(movieId, userState.userId, movieRate);
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);
    var action = 'added';
    var isViewedMovie = false;

    final movies = moviesState.userMovies.where((element) => element.id == movieId);

    if (movies.length > 0) {
      action = 'moved';

      if (movies.first.movieRate == MovieRate.liked || movies.first.movieRate == MovieRate.notLiked)
        isViewedMovie = true;
    }

    var text = 'The item $action to your Watchlist!';

    if (movieRate == MovieRate.notRated)
      text = 'The item removed from your movies!';

    if (movieRate == MovieRate.liked || movieRate == MovieRate.notLiked) {
      if (isViewedMovie) {
        text = 'Rate of the item changed!';
      } else {
        text = 'The item $action to your viewed movies!';
      }
    }

    return MIconButton(
      width: width,
      icon: icon,
      onPressedCallback: () async {
        Navigator.of(context).pop();

        await new Future.delayed(const Duration(milliseconds: 300));

        MSnackBar.showSnackBar(text, true, null);

        await new Future.delayed(const Duration(milliseconds: 300));

        rateMovie(movieId, movieRate, moviesState, userState);
      },
    );
  }
}
