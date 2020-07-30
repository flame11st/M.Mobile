// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';

import 'MoviesFilter.dart';
import 'Providers/MoviesState.dart';
import 'Shared/BoxShadowNeomorph.dart';
import 'Shared/MIconButton.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final isAnyFilterSelected = moviesState.moviesOnly ||
        moviesState.tvOnly ||
        (!moviesState.isWatchlist() && (moviesState.likedOnly ||
        moviesState.notLikedOnly));

    return BottomAppBar(
        color: Colors.transparent,
        shape: CircularNotchedRectangle(),
        child: Container(
            height: 65,
            width: double.infinity,
//            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
//                bottomLeft: Radius.circular(30.0),
//                bottomRight: Radius.circular(30.0)
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  offset: Offset(-4.0, -4.0),
                  blurRadius: 7,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: Offset(6.0, 6.0),
                  blurRadius: 7,
                ),
              ],
              color: MColors.PrimaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                MIconButton(
                  icon: Icon(
                    Icons.movie_filter,
                    color: isAnyFilterSelected ? Theme.of(context).accentColor : Theme.of(context).hintColor,
                  ),
                  onPressedCallback: () async {
                    showModalBottomSheet<void>(
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (BuildContext context) => MoviesFilter());
                  },
                ),
                MIconButton(
                  icon: Icon(
                    Icons.settings,
                    color: MColors.FontsColor,
                  ),
                  onPressedCallback: () {},
                ),
                SizedBox(
                  width: 80,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(30.0)),
                    boxShadow: BoxShadowNeomorph.circleShadow,
                    color: MColors.PrimaryColor,
//                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.only(right: 10),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                          icon: Icon(
                        Icons.monetization_on,
                        color: Colors.greenAccent,
                      )),
                      Text(
                        'Premium',
                        style: MTextStyles.BodyText,
                      )
                    ],
                  ),
                )
              ],
            )));
//
  }
}
