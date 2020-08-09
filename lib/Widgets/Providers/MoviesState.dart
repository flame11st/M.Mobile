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
  var selectedRates = {MovieRate.liked, MovieRate.notLiked};
  var selectedTypes = {MovieType.movie, MovieType.tv};

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

  bool isWatchlist() {
    var result = watchlistKey.currentState != null;

    return result;
  }

  changeMoviesOnlyFilter() {
    moviesOnly = !moviesOnly;

    if (moviesOnly) {
      selectedTypes.remove(MovieType.tv);
    } else {
      selectedTypes.add(MovieType.tv);
    }

    refreshMovies();
  }

  changeTVOnlyFilter() {
    tvOnly = !tvOnly;

    if (tvOnly) {
      selectedTypes.remove(MovieType.movie);
    } else {
      selectedTypes.add(MovieType.movie);
    }

    refreshMovies();
  }

  changeLikedOnlyFilter() {
    likedOnly = !likedOnly;

    if (likedOnly) {
      selectedRates.remove(MovieRate.notLiked);
    } else {
      selectedRates.add(MovieRate.notLiked);
    }

    refreshMovies();
  }

  changeNotLikedOnlyFilter() {
    notLikedOnly = !notLikedOnly;

    if (notLikedOnly) {
      selectedRates.remove(MovieRate.liked);
    } else {
      selectedRates.add(MovieRate.liked);
    }

    refreshMovies();
  }

  refreshMovies() {
    var actualWatchlistMovies = getWatchlistMovies();
    var actualViewedMovies = getViewedMovies();

    refreshMoviesList(watchlistMovies, actualWatchlistMovies, watchlistKey);
    refreshMoviesList(viewedMovies, actualViewedMovies, viewedListKey);

    notifyListeners();
  }

  void refreshMoviesList(List<Movie> moviesList, List<Movie> actualMoviesList,
      GlobalKey<AnimatedListState> key) {
    var moviesToAdd = new List<Movie>();
    var moviesToRemove = new List<Movie>();

    actualMoviesList.forEach((movie) {
      if (!moviesList.contains(movie)) moviesToAdd.add(movie);
    });

    moviesList.forEach((movie) {
      if (!actualMoviesList.contains(movie)) moviesToRemove.add(movie);
    });

    moviesToAdd.forEach((movie) {
      addMovieToList(movie, moviesList, key, actualMoviesList.indexOf(movie));
    });

    moviesToRemove.forEach((movie) {
      removeMovieFromList(movie, moviesList, key);
    });
  }

  getWatchlistMovies() {
    var result = userMovies
        .where((movie) =>
            movie.movieRate == MovieRate.addedToWatchlist &&
            (selectedTypes.length == 0 ||
                selectedTypes.contains(movie.movieType)))
        .toList();

    return result;
  }

  getViewedMovies() {
    var selectedRates = this.selectedRates;

    if (selectedRates.length == 0) selectedRates = {MovieRate.liked, MovieRate.notLiked};

    var result = userMovies
        .where((movie) =>
            (selectedTypes.length == 0 ||
                selectedTypes.contains(movie.movieType)) &&
                selectedRates.contains(movie.movieRate))
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
    if (movieToRate.movieRate == MovieRate.notLiked ||
        movieToRate.movieRate == MovieRate.liked) {
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

    addMovieToList(
        movieToAdd, watchlistMovies, watchlistKey, watchlistMovies.length);

    movieToAdd.movieRate = movieRate;
  }

  void addMovieToViewed(Movie movieToAdd, int movieRate) {
    if (movieToAdd.movieRate == MovieRate.addedToWatchlist) {
      removeMovieFromList(movieToAdd, watchlistMovies, watchlistKey);
    } else if (movieToAdd.movieRate == MovieRate.liked ||
        movieToAdd.movieRate == MovieRate.notLiked) {
      removeMovieFromList(movieToAdd, viewedMovies, viewedListKey);
    }

    addMovieToList(
        movieToAdd, viewedMovies, viewedListKey, viewedMovies.length);

    movieToAdd.movieRate = movieRate;
  }

  void addMovieToList(Movie movieToAdd, List<Movie> moviesList,
      GlobalKey<AnimatedListState> key, int index) {
    if (key.currentState != null) key.currentState.insertItem(index);

    moviesList.insert(index, movieToAdd);
  }

  void removeMovieFromList(Movie movieToRemove, List<Movie> moviesList,
      GlobalKey<AnimatedListState> key) {
    final index = moviesList.indexOf(movieToRemove);
    moviesList.removeAt(index);

    AnimatedListRemovedItemBuilder builder = (context, animation) {
      return buildItem(movieToRemove, animation);
    };

    if (key.currentState != null) key.currentState.removeItem(index, builder);
  }

  recalculateMovieRating(Movie movie, int updatedRate) {
    if (movie.movieRate == MovieRate.liked) movie.likedVotes -= 1;
    if (movie.movieRate == MovieRate.notLiked) movie.dislikedVotes -= 1;

    if (updatedRate == MovieRate.liked) movie.likedVotes += 1;
    if (updatedRate == MovieRate.notLiked) movie.dislikedVotes += 1;

    movie.allVotes = movie.likedVotes + movie.dislikedVotes;
    movie.rating = Movie.getMovieRating(movie.likedVotes, movie.dislikedVotes);
  }

  clear() {
    watchlistKey = new GlobalKey<AnimatedListState>();
    viewedListKey = new GlobalKey<AnimatedListState>();

    userMovies.clear();
    watchlistMovies.clear();
    viewedMovies.clear();
  }

  //Animated List area
  GlobalKey<AnimatedListState> watchlistKey =
      GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> viewedListKey =
      GlobalKey<AnimatedListState>();

  Widget buildItem(Movie movie, Animation animation) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: MovieListItem(movie: movie));
  }
}
