import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import '../../Services/ServiceAgent.dart';
import '../MovieListItem.dart';

class MoviesState with ChangeNotifier {
  final serviceAgent = new ServiceAgent();

  List<Movie> userMovies = new List<Movie>();
  List<Movie> watchlistMovies = new List<Movie>();
  List<Movie> viewedMovies = new List<Movie>();
  bool moviesOnly = false;
  bool tvOnly = false;
  bool likedOnly = false;
  bool notLikedOnly = false;

  void setUserMovies(List<Movie> userMovies) async {
    this.userMovies = userMovies;
    this.watchlistMovies = userMovies
        .where((movie) => movie.movieRate == MovieRate.addedToWatchlist)
        .toList();

    for (int offset = 0; offset < watchlistMovies.length; offset++) {
      watchlistKey.currentState.insertItem(offset);
    }

    this.viewedMovies = userMovies
        .where((movie) =>
    movie.movieRate == MovieRate.liked ||
        movie.movieRate == MovieRate.notLiked)
        .toList();

    notifyListeners();
  }

  changeMoviesOnlyFilter() {
    moviesOnly = !moviesOnly;

    refreshMovies();
  }

  changeTVOnlyFilter() {
    tvOnly = !tvOnly;

    refreshMovies();
  }

  changeLikedOnlyFilter() {
    likedOnly = !likedOnly;

    refreshMovies();
  }

  changeNotLikedOnlyFilter() {
    notLikedOnly = !notLikedOnly;

    refreshMovies();
  }

  refreshMovies() {
    var initialWatchlistMovies = userMovies
        .where((movie) => movie.movieRate == MovieRate.addedToWatchlist)
        .toList();

    var initialViewedMovies = userMovies
        .where((movie) =>
    movie.movieRate == MovieRate.liked ||
        movie.movieRate == MovieRate.notLiked)
        .toList();

    refreshMoviesList(watchlistMovies, initialWatchlistMovies, watchlistKey);
    refreshMoviesList(viewedMovies, initialViewedMovies, viewedListKey);

    notifyListeners();
  }

  getWatchlistMovies() {
    var result = watchlistMovies;

    if (moviesOnly) {
      result = result
          .where((element) => element.movieType == MovieType.movie)
          .toList();
    }

    return result;
  }

  getViewedMovies() {
    var result = viewedMovies;

    if (moviesOnly) {
      result = result
          .where((element) => element.movieType == MovieType.movie)
          .toList();
    }
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
    if (movieToRate.movieRate == MovieRate.notLiked ||
        movieToRate.movieRate == MovieRate.liked) {
      removeMovieFromList(movieToRate, viewedMovies, viewedListKey);
    } else if (movieToRate.movieRate == MovieRate.addedToWatchlist) {
      removeMovieFromList(movieToRate, watchlistMovies, watchlistKey);
    }

    userMovies.remove(movieToRate);
  }


  void refreshMoviesList(List<Movie> moviesList, List<Movie> initialMoviesList, GlobalKey<AnimatedListState> key) {
    if (moviesOnly && !tvOnly) {
      var tv = moviesList.where((movie) =>
      movie.movieType == MovieType.tv).toList();

      removeMoviesFromList(tv, moviesList, key);
    }

    if (!moviesOnly && tvOnly) {
      var moviesInWatchlist = moviesList.where((movie) =>
      movie.movieType == MovieType.movie).toList();

      removeMoviesFromList(moviesInWatchlist, moviesList, key);
    }

    if ((!moviesOnly && !tvOnly) || (moviesOnly && tvOnly)) {
      if (initialMoviesList.length != moviesList.length) {
        initialMoviesList.forEach((movie) {
          if (!moviesList.contains(movie)) {
            addMovieToList(movie, moviesList, key, initialMoviesList.indexOf(movie));
          }
        });
      }
    }
  }

  void addMovieToWatchlist(Movie movieToAdd, int movieRate) {
    if (movieToAdd.movieRate != 0) {
      removeMovieFromList(movieToAdd, viewedMovies, viewedListKey);
    }

    addMovieToList(movieToAdd, watchlistMovies, watchlistKey, watchlistMovies.length);

    movieToAdd.movieRate = movieRate;
  }

  void addMovieToViewed(Movie movieToAdd, int movieRate) {
    if (movieToAdd.movieRate == MovieRate.addedToWatchlist) {
      removeMovieFromList(movieToAdd, watchlistMovies, watchlistKey);
    }

    addMovieToList(movieToAdd, viewedMovies, viewedListKey, viewedMovies.length);

    movieToAdd.movieRate = movieRate;
  }

  void addMovieToList(Movie movieToAdd, List<Movie> moviesList,
      GlobalKey<AnimatedListState> key, int index) {
    if (key.currentState != null)
      key.currentState.insertItem(index);

    moviesList.insert(index, movieToAdd);
  }

  void removeMoviesFromList(List<Movie> moviesToRemove, List<Movie> moviesList,
      GlobalKey<AnimatedListState> key) {
    moviesToRemove.forEach((movie) {
      removeMovieFromList(movie, moviesList, key);
    });
  }

  void removeMovieFromList(Movie movieToRemove, List<Movie> moviesList,
      GlobalKey<AnimatedListState> key) {
    final index = moviesList.indexOf(movieToRemove);
    moviesList.removeAt(index);

    AnimatedListRemovedItemBuilder builder = (context, animation) {
      return buildItem(movieToRemove, animation);
    };

    if (key.currentState != null)
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
  final GlobalKey<AnimatedListState> watchlistKey =
  GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> viewedListKey =
  GlobalKey<AnimatedListState>();

  Widget buildItem(Movie movie, Animation animation) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: MovieListItem(movie: movie));
  }
}
