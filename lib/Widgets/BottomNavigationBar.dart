// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

import 'MoviesFilter.dart';
import 'Shared/BoxShadowNeomorph.dart';
import 'Shared/MIconButton.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    return BottomAppBar(
//      color: MColors.AdditionalColor,
////      shape: CircularNotchedRectangle(),
//      child: IconTheme(
//        data: IconThemeData(color: Colors.white),
//        child: Row(
//          children: [
//            IconButton(
//              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
//              icon: const Icon(Icons.menu),
//                onPressed: () {
//              },
//            ),
//          ],
//        ),
//      ),
//    );
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
                    color: MColors.FontsColor,
                  ),
                  onPressedCallback: () async {
                    showModalBottomSheet<void>(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (BuildContext context) => MoviesFilter()
                    );
                  },
                ),
                MIconButton(
                  icon: Icon(
                    Icons.settings,
                    color: MColors.FontsColor,
                  ),
                  onPressedCallback: () {},
                ),
//                FloatingActionButton(
//                  onPressed: () {
//                    print('Floating action button pressed');
//                  },
//                  child: const Icon(
//                    Icons.add,
//                    size: 35,
//                  ),
//                  backgroundColor: MColors.AdditionalColor,
//                  foregroundColor: MColors.PrimaryColor,
//                ),
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
