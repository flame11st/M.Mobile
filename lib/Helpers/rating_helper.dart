import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Objects/movie.dart';
import '../Widgets/Providers/movies_state.dart';

class RatingHelper {
  static refreshMoviesRating(List<Movie> movies, BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    for (var movie in movies) {
      final userMoviesList =
      moviesState.userMovies.where((um) => um.id == movie.id);

      if (userMoviesList.isNotEmpty) {
        movie.movieRate = userMoviesList.first.movieRate;
      } else {
        movie.movieRate = 0;
      }
    }
  }
}
