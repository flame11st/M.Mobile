import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/BoxShadowNeomorph.dart';
import 'package:provider/provider.dart';

import '../MState.dart';

class MIconButton extends StatelessWidget {
    final icon;
    final int movieRate;
    final String movieId;

    MIconButton({this.icon, this.movieRate, this.movieId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MState>(context);

    return Container(
        decoration: BoxDecoration(
            boxShadow: BoxShadowNeomorph.circleShadow,
            color: MColors.PrimaryColor,
            shape: BoxShape.circle,
        ),
        child:  IconButton(
            icon: icon,
            onPressed: (){ provider.changeMovieRate(movieId, movieRate);},
        ),
    );
  }
}
