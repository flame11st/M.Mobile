import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttericon/elusive_icons.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import '../../Services/ServiceAgent.dart';
import '../MovieListItem.dart';
import 'package:collection/collection.dart';

class MoviesState with ChangeNotifier {
  MoviesState() {
    setCachedUserMovies();
  }

  final serviceAgent = new ServiceAgent();
  final storage = new FlutterSecureStorage();

  List<Movie> cachedUserMovies = new List<Movie>();
  List<Movie> userMovies = new List<Movie>();
  List<Movie> watchlistMovies = new List<Movie>();
  List<Movie> viewedMovies = new List<Movie>();
  bool moviesOnly = false;
  bool tvOnly = false;
  bool likedOnly = false;
  bool notLikedOnly = false;
  var selectedRates = {MovieRate.liked, MovieRate.notLiked};
  var selectedTypes = {MovieType.movie, MovieType.tv};

  bool isMoviesRequested = false;
  bool isCachedMoviesLoaded = false;

  setCachedUserMovies() async {
    var storedMovies;
    try {
      storedMovies = await storage.read(key: 'movies');
    } catch (on, ex) {
      await clearStorage();
    }

    if (storedMovies == null) return;

    Iterable iterableMovies = json.decode(storedMovies);

    if (iterableMovies.length != 0) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      if (userMovies.length == 0) cachedUserMovies = movies;
    }
  }

  Future<void> setInitialData() async {
    await new Future.delayed(const Duration(milliseconds: 1));

    if (userMovies.length == 0 && cachedUserMovies.length != 0)
      setInitialUserMovies(cachedUserMovies);

    notifyListeners();
  }

  void setInitialUserMovies(List<Movie> userMovies) async {
    this.userMovies = userMovies;
    this.watchlistMovies = userMovies
        .where((movie) => movie.movieRate == MovieRate.addedToWatchlist)
        .toList();

    this.viewedMovies = userMovies
        .where((movie) =>
            movie.movieRate == MovieRate.liked ||
            movie.movieRate == MovieRate.notLiked)
        .toList();

    if (watchlistKey.currentState != null) {
      for (int offset = 0; offset < watchlistMovies.length; offset++) {
        watchlistKey.currentState.insertItem(offset);
      }
    }

    notifyListeners();
  }

  Future<void> setUserMovies(List<Movie> userMovies) async {
    isMoviesRequested = true;
    var updatedUserMovies = new List<Movie>();

    for (var i = 0; i < userMovies.length; i++) {
      var movie = userMovies[i];
      var existedMovies =
          this.userMovies.where((element) => element.id == movie.id);

      if (existedMovies.isNotEmpty) {
        existedMovies.first.updateMovie(movie);
        updatedUserMovies.add(existedMovies.first);
      } else {
        updatedUserMovies.add(movie);
      }
    }

    this.userMovies = updatedUserMovies;

    refreshMovies();

    await storage.write(key: 'movies', value: jsonEncode(userMovies));
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
      if (!moviesList.any((m) => m.id == movie.id)) {
        moviesToAdd.add(movie);
      }
    });

    moviesList.forEach((movie) {
      if (!actualMoviesList.any((m) => m.id == movie.id))
        moviesToRemove.add(movie);
    });
    
    moviesToRemove.forEach((movie) {
      removeMovieFromList(movie, moviesList, key);
    });

    moviesToAdd.forEach((movie) {
      addMovieToList(movie, moviesList, key, actualMoviesList.indexOf(movie));
    });
  }

  List<Movie> getWatchlistMovies() {
    var result = userMovies
        .where((movie) =>
            movie.movieRate == MovieRate.addedToWatchlist &&
            (selectedTypes.length == 0 ||
                selectedTypes.contains(movie.movieType)))
        .toList();

    return result;
  }

  List<Movie> getViewedMovies() {
    var selectedRates = this.selectedRates;

    if (selectedRates.length == 0)
      selectedRates = {MovieRate.liked, MovieRate.notLiked};

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

    await storage.write(key: 'movies', value: jsonEncode(userMovies));
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
      userMovies.remove(movieToAdd);
      userMovies.add(movieToAdd);
      removeMovieFromList(movieToAdd, viewedMovies, viewedListKey);
    }

    addMovieToList(movieToAdd, watchlistMovies, watchlistKey, 0);

    movieToAdd.movieRate = movieRate;
  }

  void addMovieToViewed(Movie movieToAdd, int movieRate) {
    if (movieToAdd.movieRate == MovieRate.addedToWatchlist ||
        movieToAdd.movieRate == 0) {
      removeMovieFromList(movieToAdd, watchlistMovies, watchlistKey);
      userMovies.remove(movieToAdd);
      userMovies.add(movieToAdd);

      addMovieToList(movieToAdd, viewedMovies, viewedListKey, 0);
    }
//    else if (movieToAdd.movieRate == MovieRate.liked ||
//        movieToAdd.movieRate == MovieRate.notLiked) {
//      removeMovieFromList(movieToAdd, viewedMovies, viewedListKey);
//    }

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

    if (index == -1) return;

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

  logout() async {
    await clearStorage();
    isMoviesRequested = false;
    clear();
  }

  clearStorage() async {
    await storage.delete(key: 'movies');
  }

  clear() {
    getWatchlistMovies().forEach((element) =>
        removeMovieFromList(element, watchlistMovies, watchlistKey));
    getViewedMovies().forEach(
        (element) => removeMovieFromList(element, viewedMovies, viewedListKey));

    userMovies.clear();
  }

  bool equals(List<Movie> list1, List<Movie> list2) {
    if (identical(list1, list2)) return true;
    if (list1 == null || list2 == null) return false;
    var length = list1.length;
    if (length != list2.length) return false;
    for (var i = 0; i < length; i++) {
      if (!list2
          .any((m) => m.id == list1[i].id && m.movieRate == list1[i].movieRate))
        return false;
      if (!list1
          .any((m) => m.id == list2[i].id && m.movieRate == list2[i].movieRate))
        return false;
    }
    return true;
  }

  //Animated List area
  GlobalKey<AnimatedListState> watchlistKey = GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> viewedListKey = GlobalKey<AnimatedListState>();

  Widget buildItem(Movie movie, Animation animation) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: MovieListItem(movie: movie));
  }
}
