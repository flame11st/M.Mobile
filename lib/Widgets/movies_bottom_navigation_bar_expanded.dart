import 'package:flutter/material.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'Shared/md3_ui.dart';
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
    return Md3LiquidGlass(
        margin: const EdgeInsets.fromLTRB(
          Md3Spacing.x12,
          0,
          Md3Spacing.x12,
          Md3Spacing.x12,
        ),
        borderRadius: BorderRadius.circular(Md3Radius.card),
        child: SizedBox(
          height: 100,
          child: MovieRateButtons(
            movie: movie,
            fromSearch: fromSearch,
            closeParentOnRate: false,
            shouldRequestReview: shouldRequestReview,
            moviesList: moviesList,
          ),
        ));
  }
}
