import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Objects/Movie.dart';
import '../Widgets/Providers/MoviesState.dart';

class RatingHelper {
  static refreshMoviesRating(List<Movie> movies, BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    movies.forEach((movie) {
      final userMoviesList =
      moviesState.userMovies.where((um) => um.id == movie.id);

      if (userMoviesList.length > 0) {
        movie.movieRate = userMoviesList.first.movieRate;
      } else {
        movie.movieRate = 0;
      }
    });
  }
}