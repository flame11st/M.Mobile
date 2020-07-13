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
//        this.userMovies = userMovies;
    this.watchlistMovies = userMovies.where((movie) =>
    movie.movieRate == MovieRate.addedToWatchlist).toList();

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

    if (movieRate == MovieRate.liked || movieRate == MovieRate.notLiked) {
      final foundMovie = watchlistMovies.where((movie) => movie.id == movieId).first;
      final index = watchlistMovies.indexOf(foundMovie);

      viewedMovies.add(foundMovie);
      watchlistMovies.removeAt(index);

      AnimatedListRemovedItemBuilder builder = (context, animation) {
        return buildItem(foundMovie, animation);
      };

      watchlistKey.currentState.removeItem(index, builder);
    } else if (movieRate == MovieRate.addedToWatchlist) {
      final foundMovie = viewedMovies.where((movie) => movie.id == movieId).first;
      final index = viewedMovies.indexOf(foundMovie);

      watchlistMovies.add(foundMovie);
      viewedMovies.removeAt(index);

      AnimatedListRemovedItemBuilder builder = (context, animation) {
        return buildItem(foundMovie, animation);
      };

      viewedListKey.currentState.removeItem(index, builder);
    }

    notifyListeners();
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