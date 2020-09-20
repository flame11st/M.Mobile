import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttericon/elusive_icons.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import '../../Services/ServiceAgent.dart';
import '../MovieListItem.dart';
import 'package:collection/collection.dart';

import '../Premium.dart';

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
  List<DropdownMenuItem<String>> genres = new List<DropdownMenuItem<String>>();
  bool moviesOnly = false;
  bool tvOnly = false;
  bool likedOnly = false;
  bool notLikedOnly = false;
  DateTime dateFrom;
  DateTime dateTo;
  String selectedGenre;

  DateTime dateMin;
  DateTime dateMax;

  var selectedRates = {MovieRate.liked, MovieRate.notLiked};
  var selectedTypes = {MovieType.movie, MovieType.tv};

  int viewedLimit = 10;
  int page = 1;
  bool showMoreButton = false;
  Movie currentLatestMovie;

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

    setGenres();

    notifyListeners();
  }

  void setInitialUserMovies(List<Movie> userMovies) async {
    this.userMovies = userMovies;

    refreshMovies();
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

    setGenres();

    refreshMovies();

    await storage.write(key: 'movies', value: jsonEncode(userMovies));
  }

  setGenres() {
    genres.clear();

    var genresList = new List<String>();

    userMovies.forEach((element) {
      genresList.addAll(element.genres);
    });

    genresList.sort();

    genresList.forEach((element) {
      if (!genres.any((genre) => genre.value == element)) {
        genres.add(DropdownMenuItem(
          value: element,
          child: Text(element),
        ));
      }
    });
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

  changeDateFromFilter(DateTime value) {
    this.dateFrom = value;

    refreshMovies();
  }

  changeDateToFilter(DateTime value) {
    this.dateTo = value;

    refreshMovies();
  }

  changeGenreFilter(String genre) {
    selectedGenre = genre;

    refreshMovies();
  }

  isAnyFilterSelected() {
    return moviesOnly ||
        tvOnly ||
        (!isWatchlist() && (likedOnly || notLikedOnly)) ||
        isDateToSelected() ||
        isDateFromSelected() ||
        selectedGenre != null;
  }

  clearAllFilters() {
    dateFrom = dateMin;
    dateTo = dateMax;
    moviesOnly = false;
    tvOnly = false;
    likedOnly = false;
    notLikedOnly = false;
    selectedGenre = null;

    selectedRates = {MovieRate.liked, MovieRate.notLiked};
    selectedTypes = {MovieType.movie, MovieType.tv};

    refreshMovies();
  }

  bool isDateToSelected() {
    return dateTo != null && dateTo.difference(dateMax).inDays != 0;
  }

  bool isDateFromSelected() {
    return dateFrom != null &&
        dateFrom
                .difference(
                    dateMin.subtract(new Duration(hours: 23, minutes: 59)))
                .inDays !=
            0;
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
                selectedTypes.contains(movie.movieType)) &&
            (selectedGenre == null || movie.genres.contains(selectedGenre)))
        .toList();

    return result;
  }

  List<Movie> getViewedMovies() {
    List<Movie> allViewedMovies = getAllViewedMovies();

    var shouldChangeDateTo = dateMax == dateTo;

    refreshDates(allViewedMovies, shouldChangeDateTo);

    var filteredMovies = allViewedMovies
        .where((movie) =>
            movie.updated.isAfter(dateFrom) &&
            movie.updated.isBefore(dateTo.add(new Duration(days: 1))))
        .toList();

    var showedMoviesCount = viewedLimit * page;

    if (filteredMovies.length > showedMoviesCount) {
      showMoreButton = true;
      currentLatestMovie = filteredMovies[showedMoviesCount - 1];
    } else {
      showMoreButton = false;
      currentLatestMovie = null;
    }

    return filteredMovies.take(showedMoviesCount).toList();
  }

  void refreshDates(List<Movie> allViewedMovies, bool shouldChangeDateTo) {
    if (dateMin == null ||
        (allViewedMovies.isNotEmpty &&
            dateFrom.isAfter(allViewedMovies.last.updated)))
      dateMin = allViewedMovies.last.updated;

    if (dateMax == null ||
        (allViewedMovies.isNotEmpty &&
            dateMax.isBefore(
                allViewedMovies.first.updated.add(new Duration(days: 1))))) {
      dateMax = allViewedMovies.first.updated;

      if (shouldChangeDateTo) dateTo = dateMax;
    }

    if (dateFrom == null) dateFrom = dateMin;
    if (dateTo == null) dateTo = dateMax;
  }

  List<Movie> getAllViewedMovies() {
    var selectedRates = this.selectedRates;

    if (selectedRates.length == 0)
      selectedRates = {MovieRate.liked, MovieRate.notLiked};

    var result = userMovies
        .where((movie) =>
            (selectedTypes.length == 0 ||
                selectedTypes.contains(movie.movieType)) &&
            selectedRates.contains(movie.movieRate) &&
            (selectedGenre == null || movie.genres.contains(selectedGenre)))
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
      movieToRate.updated = DateTime.now();
      userMovies.insert(0, movieToRate);
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
      userMovies.insert(0, movieToAdd);
      // removeMovieFromList(movieToAdd, viewedMovies, viewedListKey);

      if (movieToAdd == currentLatestMovie) {
        currentLatestMovie = viewedMovies.last;
      }
    }

    // addMovieToList(movieToAdd, watchlistMovies, watchlistKey, 0);

    movieToAdd.movieRate = movieRate;

    refreshMovies();
  }

  void addMovieToViewed(Movie movieToAdd, int movieRate) {
    if (movieToAdd.movieRate == MovieRate.addedToWatchlist ||
        movieToAdd.movieRate == 0) {
      // removeMovieFromList(movieToAdd, watchlistMovies, watchlistKey);
      userMovies.remove(movieToAdd);
      userMovies.insert(0, movieToAdd);

      // addMovieToList(movieToAdd, viewedMovies, viewedListKey, 0);
    }

    movieToAdd.movieRate = movieRate;

    refreshMovies();
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

//  bool equals(List<Movie> list1, List<Movie> list2) {
//    if (identical(list1, list2)) return true;
//    if (list1 == null || list2 == null) return false;
//    var length = list1.length;
//    if (length != list2.length) return false;
//    for (var i = 0; i < length; i++) {
//      if (!list2
//          .any((m) => m.id == list1[i].id && m.movieRate == list1[i].movieRate))
//        return false;
//      if (!list1
//          .any((m) => m.id == list2[i].id && m.movieRate == list2[i].movieRate))
//        return false;
//    }
//    return true;
//  }

  showMoreMovies(BuildContext context, bool isPremium) {
    if (isPremium) {
      page += 1;
      refreshMovies();
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (ctx) => Premium()));
    }
  }

  //Animated List area
  GlobalKey<AnimatedListState> watchlistKey = GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> viewedListKey = GlobalKey<AnimatedListState>();

  Widget buildItem(Movie movie, Animation animation,
      {bool isPremium = false, BuildContext context}) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: Column(
          children: [
            MovieListItem(movie: movie),
            if (currentLatestMovie == movie)
              SizedBox(
                height: 15,
              ),
            if (currentLatestMovie == movie)
              MButton(
                prependIcon:
                    isPremium ? Icons.expand_more : Icons.monetization_on,
                prependIconColor:
                    isPremium ? Theme.of(context).hintColor : Colors.green,
                width: 250,
                height: 40,
                active: true,
                text: 'Show more ${isPremium ? '' : ' (Premium only)'}',
                onPressedCallback: () => showMoreMovies(context, isPremium),
              ),
            if (currentLatestMovie == movie)
              SizedBox(
                height: 5,
              ),
          ],
        ));
  }
}
