import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Enums/MovieListType.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import '../../Services/ServiceAgent.dart';
import '../MovieListItem.dart';

import '../Premium.dart';

class MoviesState with ChangeNotifier {
  MoviesState() {
    setCachedUserMovies();
    setCachedMoviesLists();
  }

  final serviceAgent = new ServiceAgent();
  final storage = new FlutterSecureStorage();

  List<Movie> cachedUserMovies = new List<Movie>();
  List<Movie> userMovies = new List<Movie>();
  List<Movie> watchlistMovies = new List<Movie>();
  List<Movie> viewedMovies = new List<Movie>();
  List<MoviesList> externalMoviesLists = new List<MoviesList>();
  List<MoviesList> personalMoviesLists = new List<MoviesList>();
  List<DropdownMenuItem<String>> genres = new List<DropdownMenuItem<String>>();
  bool moviesOnly = false;
  bool tvOnly = false;
  bool likedOnly = false;
  bool notLikedOnly = false;
  DateTime dateFrom;
  DateTime dateTo;
  String selectedGenre;
  int currentTabIndex = 0;

  DateTime dateMin;
  DateTime dateMax;

  var selectedRates = {MovieRate.liked, MovieRate.notLiked};
  var selectedTypes = {MovieType.movie, MovieType.tv};

  int viewedLimit = 35;
  int page = 1;
  bool showMoreButton = false;
  Movie currentLatestMovie;

  bool isMoviesRequested = false;
  bool isMoviesListsRequested = false;
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
    refreshDates();
  }

  Future<void> setUserMovies(List<Movie> userMovies) async {
    isMoviesRequested = true;
    updateUserMovies(userMovies, false);

    setGenres();

    refreshMovies();
    refreshDates();

    await storage.write(key: 'movies', value: jsonEncode(userMovies));
  }

  void updateUserMoviesIncognito(List<Movie> movies){
    updateUserMovies(movies, true);

    setGenres();

    refreshMovies();
    refreshDates();
  }

  void updateUserMovies(List<Movie> userMovies, bool shouldSetRate) {
    var updatedUserMovies = new List<Movie>();

    for (var i = 0; i < userMovies.length; i++) {
      var movie = userMovies[i];
      var existedMovies =
          this.userMovies.where((element) => element.id == movie.id);

      if (existedMovies.isNotEmpty) {
        if (shouldSetRate) {
          movie.movieRate = existedMovies.first.movieRate;
        }

        existedMovies.first.updateMovie(movie);
        updatedUserMovies.add(existedMovies.first);
      } else {
        updatedUserMovies.add(movie);
      }
    }

    this.userMovies = updatedUserMovies;
  }

  setCachedMoviesLists() async {
    var storedExternalMoviesLists;
    var storedPersonalMoviesLists;
    try {
      storedExternalMoviesLists = await storage.read(key: 'externalMoviesLists');
      storedPersonalMoviesLists = await storage.read(key: 'personalMoviesLists');
    } catch (on, ex) {
      await clearStorage();
    }

    if (storedExternalMoviesLists != null) {
      var externalMoviesListValue = getMoviesListFromJson(storedExternalMoviesLists);

      if (externalMoviesListValue != null)
        setExternalMoviesLists(externalMoviesListValue);
    }

    if (storedPersonalMoviesLists != null) {
      var personalMoviesListValue = getMoviesListFromJson(storedPersonalMoviesLists);

      if (personalMoviesListValue != null)
        setPersonalMoviesLists(personalMoviesListValue);
    }
  }

  getMoviesListFromJson(String jsonString) {
    Iterable iterableMoviesLists = json.decode(jsonString);
    List<MoviesList> moviesLists;

    if (iterableMoviesLists.length != 0) {
      moviesLists = iterableMoviesLists.map((model) {
        return MoviesList.fromJson(model);
      }).toList();
    }

    return moviesLists;
  }

  setInitialMoviesLists(List<MoviesList> moviesLists) async {
    final externalLists = moviesLists
        .where((list) => list.movieListType == MovieListType.external)
        .toList();
    final personalLists = moviesLists
        .where((list) => list.movieListType == MovieListType.personal)
        .toList();

    await storage.write(key: 'externalMoviesLists', value: jsonEncode(externalLists));
    await storage.write(key: 'personalMoviesLists', value: jsonEncode(personalLists));

    setExternalMoviesLists(externalLists);
    setPersonalMoviesLists(personalLists);
  }

  setInitialMoviesListsIncognito(List<MoviesList> moviesLists) async {
    final externalLists = moviesLists
        .where((list) => list.movieListType == MovieListType.external)
        .toList();

    await storage.write(key: 'externalMoviesLists', value: jsonEncode(externalLists));

    setExternalMoviesLists(externalLists);

    notifyListeners();
  }

  setExternalMoviesLists(List<MoviesList> moviesLists) {
    this.externalMoviesLists = getMappedMoviesList(moviesLists);
  }

  setPersonalMoviesLists(List<MoviesList> moviesLists) {
    this.personalMoviesLists = getMappedMoviesList(moviesLists);

    notifyListeners();
  }

  getMappedMoviesList(List<MoviesList> moviesLists) {
    var lists = moviesLists.map((ml) {
      final movies = ml.listMovies.map((movie) {
        final userMovie = userMovies.where((um) => um.id == movie.id);

        if (userMovie.length > 0) {
          movie.movieRate = userMovie.first.movieRate;
        } else {
          movie.movieRate = MovieRate.notRated;
        }

        return movie;
      }).toList();

      ml.listMovies = movies;

      return ml;
    }).toList();

    return lists;
  }

  addMoviesList(String listName, int order) async {
    this.personalMoviesLists.add(new MoviesList(
        name: listName,
        movieListType: MovieListType.personal,
        order: order,
        listMovies: []));

    storage.write(key: 'personalMoviesLists', value: jsonEncode(this.personalMoviesLists));
  }

  renameMoviesList(String oldName, String newName) async {
    final list = this.personalMoviesLists.singleWhere((element) => element.name == oldName);

    list.name = newName;

    storage.write(key: 'personalMoviesLists', value: jsonEncode(this.personalMoviesLists));
  }

  removeMoviesList(String listName) {
    this.personalMoviesLists =
        this.personalMoviesLists.where((element) => element.name != listName).toList();

    storage.write(key: 'personalMoviesLists', value: jsonEncode(this.personalMoviesLists));
  }

  addMovieToPersonalList(String listName, Movie movie) {
    final list = personalMoviesLists.singleWhere((element) => element.name == listName);

    list.listMovies.add(movie);

    final listsStringValue = jsonEncode(this.personalMoviesLists);

    storage.write(key: 'personalMoviesLists', value: listsStringValue);
  }

  removeMovieFromPersonalList(String listName, Movie movie) {
    final list = personalMoviesLists.singleWhere((element) => element.name == listName);

    removeMovieFromList(movie, list.listMovies, MyGlobals.personalListsKey);

    final listsStringValue = jsonEncode(this.personalMoviesLists);

    storage.write(key: 'personalMoviesLists', value: listsStringValue);
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

  setCurrentTabIndex(int value) {
    currentTabIndex = value;

    notifyListeners();
  }

  bool isWatchlist() {
    var result = currentTabIndex == 0;

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

    if (allViewedMovies.isEmpty) return new List<Movie>();

    var filteredMovies;

    if (isDateFromSelected() || isDateToSelected()) {
      filteredMovies = allViewedMovies
          .where((movie) =>
              movie.updated
                  .isAfter(dateFrom.subtract(new Duration(minutes: 1))) &&
              movie.updated.isBefore(dateTo.add(new Duration(days: 1))))
          .toList();
    } else {
      filteredMovies = allViewedMovies;
    }

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

  void refreshDates() {
    List<Movie> allViewedMovies = userMovies
        .where((movie) =>
            movie.movieRate == MovieRate.liked ||
            movie.movieRate == MovieRate.notLiked)
        .toList();

    if (allViewedMovies.isNotEmpty) {
      if (dateMin == dateFrom ||
          dateFrom == null ||
          dateFrom.isBefore(allViewedMovies.last.updated))
        dateFrom = allViewedMovies.last.updated;

      dateMin = allViewedMovies.last.updated;

      if (dateMax == dateTo ||
          dateTo == null ||
          dateTo.isAfter(allViewedMovies.first.updated))
        dateTo = allViewedMovies.first.updated;

      dateMax = allViewedMovies.first.updated;
    } else {
      dateFrom = dateMin = dateMax = dateTo = null;
    }
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

  changeMovieRate(String movieId, int movieRate, bool isIncognitoMode, Movie movie) async {
    if (movieId == null) return;

    Movie movieToRate;
    var foundMovies = userMovies.where((m) => m.id == movieId);

    if (movie != null && (movie.actors.isNotEmpty || movie.directors.isNotEmpty || movie.genres.isNotEmpty))
    {
      movieToRate = movie;
    } else if (foundMovies.length == 0) {
      final moviesResponse = await serviceAgent.getMovie(movieId);
      movieToRate = Movie.fromJson(json.decode(moviesResponse.body));
    } else {
      movieToRate = foundMovies.first;
    }

    if (foundMovies.length == 0) {
      userMovies.insert(0, movieToRate);
    }

    if (!isIncognitoMode) recalculateMovieRating(movieToRate, movieRate);

    if (movieRate == MovieRate.liked || movieRate == MovieRate.notLiked) {
      addMovieToViewed(movieToRate, movieRate);
    } else if (movieRate == MovieRate.addedToWatchlist) {
      addMovieToWatchlist(movieToRate, movieRate);
    } else if (movieRate == MovieRate.notRated) {
      removeMovieRate(movieToRate);
    }

    setRateToMovieInLists(movieId, movieRate);

    refreshMovies();
    refreshDates();
    setGenres();

    await storage.write(key: 'movies', value: jsonEncode(userMovies));
  }

  // Future<void> updateMoviePosterPath(Movie movie, String posterPath) async {
  //   await storage.write(key: 'movies', value: jsonEncode(userMovies));
  // }

  void setRateToMovieInLists(String movieId, int rate) {
    externalMoviesLists.forEach((element) {
      var movies = element.listMovies.where((element) => element.id == movieId);

      if (movies.length > 0) movies.first.movieRate = rate;
    });

    personalMoviesLists.forEach((element) {
      var movies = element.listMovies.where((element) => element.id == movieId);

      if (movies.length > 0) movies.first.movieRate = rate;
    });
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
      movieToAdd.updated = DateTime.now().toUtc();

      if (movieToAdd == currentLatestMovie) {
        currentLatestMovie = viewedMovies.last;
      }
    }

    movieToAdd.movieRate = movieRate;
  }

  void addMovieToViewed(Movie movieToAdd, int movieRate) {
    if (movieToAdd.movieRate == MovieRate.addedToWatchlist ||
        movieToAdd.movieRate == 0) {
      userMovies.remove(movieToAdd);
      userMovies.insert(0, movieToAdd);
      movieToAdd.updated = DateTime.now().toUtc();
    }

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
    clear();
    clearAllFilters();
    isMoviesRequested = false;
    currentTabIndex = 0;
    dateTo = null;
    dateMax = null;
    dateFrom = null;
    dateMin = null;
    isMoviesListsRequested = false;
  }

  clearStorage() async {
    await storage.delete(key: 'movies');
    await storage.delete(key: 'externalMoviesLists');
    await storage.delete(key: 'personalMoviesLists');
  }

  clear() async {
    getWatchlistMovies().forEach((element) =>
        removeMovieFromList(element, watchlistMovies, watchlistKey));
    getViewedMovies().forEach(
        (element) => removeMovieFromList(element, viewedMovies, viewedListKey));

    watchlistMovies.clear();
    viewedMovies.clear();
    userMovies.clear();
    cachedUserMovies.clear();
    personalMoviesLists.clear();
    externalMoviesLists = getMappedMoviesList(externalMoviesLists);

    await clearStorage();
  }

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
  // GlobalKey<AnimatedListState> personalListKey;

  Widget buildItem(Movie movie, Animation animation,
      {bool isPremium = false, BuildContext context}) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: Column(
          children: [
            MovieListItem(movie: movie, shouldRequestReview: true,),
            // MovieListItem(movie: movie, imageUrl: imageBaseUrl,),
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
