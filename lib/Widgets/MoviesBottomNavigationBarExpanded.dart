import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'Shared/MovieRateButtons.dart';

class MoviesBottomNavigationBarExpanded extends StatelessWidget {
  final Movie movie;
  final bool fromSearch;

  const MoviesBottomNavigationBarExpanded(
      {Key key,
      this.fromSearch = false, this.movie})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        color: Theme.of(context).primaryColor,
        child: MovieRateButtons(
          movie: movie,
          fromSearch: fromSearch,
        ));
  }
}
