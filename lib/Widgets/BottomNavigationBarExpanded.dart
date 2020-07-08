// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/BoxShadowNeomorph.dart';
import 'package:provider/provider.dart';

import 'MState.dart';

class MoviesBottomNavigationBarExpanded extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MState>(context);

    return BottomAppBar(
      color: MColors.PrimaryColor,
      child: Container(
        height: 60,
        margin: EdgeInsets.fromLTRB(10, 5, 10, 20),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: Offset(-6.0, -6.0),
              blurRadius: 16,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: Offset(6.0, 6.0),
              blurRadius: 8,
            ),
          ],
          color: MColors.PrimaryColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text("")
      )

    );
  }
}

