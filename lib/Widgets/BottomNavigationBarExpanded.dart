// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/BoxShadowNeomorph.dart';
import 'package:provider/provider.dart';

import 'MState.dart';
import 'Shared/MIconButton.dart';

class MoviesBottomNavigationBarExpanded extends StatelessWidget {
  final movieId;

  const MoviesBottomNavigationBarExpanded({Key key, this.movieId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: MColors.PrimaryColor,
      child: Container(
        height: 60,
        margin: EdgeInsets.fromLTRB(10, 5, 10, 20),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.15),
              offset: Offset(-4.0, -4.0),
              blurRadius: 16,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: Offset(6.0, 6.0),
              blurRadius: 8,
            ),
          ],
          color: MColors.PrimaryColor,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
                MIconButton(
                    icon: Icon(Icons.thumb_up, color: MColors.FontsColor,),
                    movieId: movieId,
                    movieRate: MovieRate.liked,
                ),
                MIconButton(
                    icon: Icon(Icons.thumb_down, color: MColors.FontsColor,),
                    movieId: movieId,
                    movieRate: MovieRate.notLiked,
                ),
                MIconButton(
                    icon: Icon(Icons.add_to_queue, color: MColors.FontsColor,),
                    movieId: movieId,
                    movieRate: MovieRate.addedToWatchlist,
                )
            ],
        )

      )

    );
  }
}

