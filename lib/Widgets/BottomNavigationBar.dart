// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';

import 'MState.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MState>(context);

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
  }
}

