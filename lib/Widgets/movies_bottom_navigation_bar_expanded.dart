import 'package:flutter/material.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'Shared/movie_rate_buttons.dart';

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

