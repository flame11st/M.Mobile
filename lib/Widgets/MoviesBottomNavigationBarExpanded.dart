import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'Shared/MovieRateButtons.dart';

class MoviesBottomNavigationBarExpanded extends StatelessWidget {
  final Movie movie;
  final bool fromSearch;
  final bool shouldRequestReview;
  final MoviesList? moviesList;

  const MoviesBottomNavigationBarExpanded(
      {super.key,
      this.fromSearch = false,
      required this.movie,
      this.shouldRequestReview = false,
      this.moviesList});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        height: 100,
        color: Theme.of(context).primaryColor,
        child: MovieRateButtons(
          movie: movie,
          fromSearch: fromSearch,
          shouldRequestReview: shouldRequestReview,
          moviesList: moviesList,
        ));
  }
}
