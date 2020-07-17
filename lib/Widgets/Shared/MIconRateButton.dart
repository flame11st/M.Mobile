import 'package:flutter/material.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Widgets/Providers/MoviesState.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/MIconButton.dart';
import 'package:provider/provider.dart';

class MIconRateButton extends StatelessWidget {
  final icon;
  final int movieRate;
  final String movieId;
  final serviceAgent = new ServiceAgent();
  final width;

  MIconRateButton({this.icon, this.movieRate, this.movieId, this.width});

  rateMovie(String movieId, int movieRate, MoviesState moviesState, UserState userState) async {
    moviesState.changeMovieRate(movieId, movieRate);

    serviceAgent.state = userState;
    await serviceAgent.rateMovie(movieId, userState.userId, movieRate);
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    return MIconButton(
      width: width,
      icon: icon,
      onPressedCallback: () async {
        Navigator.of(context).pop();
        await new Future.delayed(const Duration(milliseconds: 500));
        rateMovie(movieId, movieRate, moviesState, userState);
      },
    );
  }
}
