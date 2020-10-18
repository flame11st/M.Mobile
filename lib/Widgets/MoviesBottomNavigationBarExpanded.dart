// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'Shared/MovieRateButtons.dart';

class MoviesBottomNavigationBarExpanded extends StatelessWidget {
  final String movieId;
  final int movieRate;
  final String movieTitle;
  final bool fromSearch;

  const MoviesBottomNavigationBarExpanded(
      {Key key, this.movieId, this.movieRate, this.movieTitle, this.fromSearch = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        color: Theme.of(context).primaryColor,
        child: MovieRateButtons(
          movieId: movieId,
          movieRate: movieRate,
          movieTitle: movieTitle,
          fromSearch: fromSearch,
        ));
  }
}
