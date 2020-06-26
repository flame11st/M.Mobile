// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.cyanAccent,
      shape: CircularNotchedRectangle(),
      child: IconTheme(
        data: IconThemeData(color: Colors.black54),
        child: Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(Icons.menu),
              onPressed: () {
                print('Menu button pressed');
              },
            ),
          ],
        ),
      ),
    );
  }
}

