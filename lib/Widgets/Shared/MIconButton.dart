import 'package:flutter/material.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Providers/MoviesState.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/BoxShadowNeomorph.dart';
import 'package:provider/provider.dart';

class MIconButton extends StatelessWidget {
  final icon;
  final int movieRate;
  final String movieId;
  final serviceAgent = new ServiceAgent();

  MIconButton({this.icon, this.movieRate, this.movieId});

  rateMovie(String movieId, int movieRate, MoviesState moviesState, UserState userState) async {
    moviesState.changeMovieRate(movieId, movieRate);

    serviceAgent.state = userState;
    await serviceAgent.rateMovie(movieId, userState.userId, movieRate);
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    return Container(
      decoration: BoxDecoration(
        boxShadow: BoxShadowNeomorph.circleShadow,
        color: MColors.PrimaryColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: icon,
        onPressed: () {
          rateMovie(movieId, movieRate, moviesState, userState);
        },
      ),
    );
  }
}
