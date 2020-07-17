import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Objects/Movie.dart';
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

    var foundMovies = userMovies.where((m) => m.id == movieId);
    Movie movieToRate;

    if (foundMovies.length == 0) {
      final moviesResponse = await serviceAgent.getMovie(movieId);
      movieToRate = Movie.fromJson(json.decode(moviesResponse.body));
      userMovies.add(movieToRate);
    } else {
      movieToRate = foundMovies.first;
    }

    recalculateMovieRating(movieToRate, movieRate);

    if (movieRate == MovieRate.liked || movieRate == MovieRate.notLiked) {
      addMovieToViewed(movieToRate, movieRate);
    } else if (movieRate == MovieRate.addedToWatchlist) {
      addMovieToWatchlist(movieToRate, movieRate);
    } else if (movieRate == MovieRate.notRated) {
      removeMovieRate(movieToRate);
    }

    notifyListeners();
  }

  void removeMovieRate(Movie movieToRate) {
    if (movieToRate.movieRate == MovieRate.notLiked || movieToRate.movieRate == MovieRate.liked) {
      removeMovieFromList(movieToRate, viewedMovies, viewedListKey);
    } else if (movieToRate.movieRate == MovieRate.addedToWatchlist) {
      removeMovieFromList(movieToRate, watchlistMovies, watchlistKey);
    }

    userMovies.remove(movieToRate);
  }

  void addMovieToWatchlist(Movie movieToAdd, int movieRate) {
    if (movieToAdd.movieRate != 0) {
      removeMovieFromList(movieToAdd, viewedMovies, viewedListKey);
    }

    watchlistMovies.add(movieToAdd);
    watchlistKey.currentState.insertItem(viewedMovies.length);
    movieToAdd.movieRate = movieRate;
  }

  void addMovieToViewed(Movie movieToAdd, int movieRate) {
    if (movieToAdd.movieRate == MovieRate.addedToWatchlist) {
      removeMovieFromList(movieToAdd, watchlistMovies, watchlistKey);
    }

    viewedListKey.currentState.insertItem(viewedMovies.length);
    viewedMovies.add(movieToAdd);

    movieToAdd.movieRate = movieRate;
  }

  void removeMovieFromList(Movie movieToRemove, List<Movie> moviesList, GlobalKey<AnimatedListState> key) {
    final index = moviesList.indexOf(movieToRemove);
    moviesList.removeAt(index);

    AnimatedListRemovedItemBuilder builder = (context, animation) {
      return buildItem(movieToRemove, animation);
    };

    key.currentState.removeItem(index, builder);
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