// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: MColors.AdditionalColor,
      shape: CircularNotchedRectangle(),
      child: IconTheme(
        data: IconThemeData(color: Colors.white),
        child: Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(Icons.menu),
                onPressed: () {
              },
            ),
          ],
        ),
      ),
    );
//    return BottomAppBar(
//            shape: CircularNotchedRectangle(),
//            child: Container(
//                height: 50,
//                width: double.infinity,
//                decoration: BoxDecoration(
//                  boxShadow: [
//                    BoxShadow(
//                      color: Colors.black.withOpacity(0.3),
//                      offset: Offset(-4.0, -4.0),
//                      blurRadius: 16,
//                    ),
//                    BoxShadow(
//                      color: Colors.black.withOpacity(0.4),
//                      offset: Offset(6.0, 6.0),
//                      blurRadius: 16,
//                    ),
//                  ],
//                  color: MColors.AdditionalColor,
//                ),
//                child: Text("")
//                )
//            );
//
  }
}

