import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Widgets/MyMovies.dart';
import '../../Services/ServiceAgent.dart';
import '../MovieListItem.dart';

class MoviesState with ChangeNotifier {
  final serviceAgent = new ServiceAgent();

  List<Movie> userMovies = new List<Movie>();
  List<Movie> watchlistMovies = new List<Movie>();
  List<Movie> viewedMovies = new List<Movie>();

  void setUserMovies(List<Movie> userMovies) async {
    this.userMovies = userMovies;
    this.watchlistMovies = userMovies.where((movie) =>
    movie.movieRate == MovieRate.addedToWatchlist).toList();

    for (int offset = 0; offset < watchlistMovies.length; offset++) {
      watchlistKey.currentState.insertItem(offset);
    }

    this.viewedMovies = userMovies.where((movie) =>
    movie.movieRate == MovieRate.liked || movie.movieRate == MovieRate.notLiked)
        .toList();

    notifyListeners();
  }

  getWatchlistMovies() {
    final result = this.userMovies.where((movie) =>
    movie.movieRate == MovieRate.addedToWatchlist).toList();
    return result;
  }

  getViewedMovies() {
    final result = this.userMovies
        .where((movie) =>
    movie.movieRate == MovieRate.liked || movie.movieRate == MovieRate.notLiked)
        .toList();
    return result;
  }

  changeMovieRate(String movieId, int movieRate) async {
    if (movieId == null) return;

    var foundMovies = userMovies.where((movie) => movie.id == movieId);

    if (foundMovies.length == 0) {
      // TODO: Add initial adding logic
      return;
    }

    final foundMovie = foundMovies.first;
    recalculateMovieRating(foundMovie, movieRate);

    if (movieRate == MovieRate.liked || movieRate == MovieRate.notLiked) {
      if (foundMovie.movieRate == MovieRate.addedToWatchlist) {
        final index = watchlistMovies.indexOf(foundMovie);

        viewedMovies.add(foundMovie);
        watchlistMovies.removeAt(index);

        AnimatedListRemovedItemBuilder builder = (context, animation) {
          return buildItem(foundMovie, animation);
        };

        watchlistKey.currentState.removeItem(index, builder);
      }

      foundMovie.movieRate = movieRate;

    } else if (movieRate == MovieRate.addedToWatchlist) {
//      final foundMovie = viewedMovies.where((movie) => movie.id == movieId).first;
      final index = viewedMovies.indexOf(foundMovie);

      watchlistMovies.add(foundMovie);
      viewedMovies.removeAt(index);

      AnimatedListRemovedItemBuilder builder = (context, animation) {
        return buildItem(foundMovie, animation);
      };

      foundMovie.movieRate = movieRate;
      viewedListKey.currentState.removeItem(index, builder);
    }

    notifyListeners();
  }

  recalculateMovieRating(Movie movie, int updatedRate) {
    if (movie.movieRate == MovieRate.liked) movie.likedVotes -= 1;
    if (movie.movieRate == MovieRate.notLiked) movie.dislikedVotes -= 1;

    if (updatedRate == MovieRate.liked) movie.likedVotes += 1;
    if (updatedRate == MovieRate.notLiked) movie.dislikedVotes += 1;

    movie.allVotes = movie.likedVotes + movie.dislikedVotes;
    movie.rating = Movie.getMovieRating(movie.likedVotes, movie.dislikedVotes);
  }

  //Animated List area
  final GlobalKey<AnimatedListState> watchlistKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> viewedListKey = GlobalKey<AnimatedListState>();

  Widget buildItem(Movie movie, Animation animation) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: MovieListItem(movie: movie)
    );
  }
}