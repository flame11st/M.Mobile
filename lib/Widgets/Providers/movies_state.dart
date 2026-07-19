import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Variables/variables.dart';
import '../../Services/service_agent.dart';
import '../movie_list_item.dart';

class MoviesState with ChangeNotifier {
  MoviesState() {
    setCachedUserMovies();
    unawaited(_discardLegacyExternalListCache());
    setCachedMoviesLists();
  }

  final serviceAgent = ServiceAgent();
  final storage = const FlutterSecureStorage();
  static const _cacheReadTimeout = Duration(seconds: 2);
  static const _movieCacheWriteDebounce = Duration(milliseconds: 700);
  Timer? _movieCacheWriteTimer;
  Timer? _personalListsCacheWriteTimer;

  List<Movie> cachedUserMovies = [];
  List<Movie> userMovies = [];
  List<Movie> watchlistMovies = [];
  List<Movie> viewedMovies = [];
  List<Movie> starterDeckMovies = [];
  List<MoviesList> externalMoviesLists = [];
  List<MoviesList> personalMoviesLists = [];
  List<DropdownMenuItem<String>> genres = [];
  bool moviesOnly = false;
  bool tvOnly = false;
  bool likedOnly = false;
  bool notLikedOnly = false;
  bool okayOnly = false;
  DateTime? dateFrom;
  DateTime? dateTo;
  String? selectedGenre;
  int currentTabIndex = 0;

  DateTime? dateMin;
  DateTime? dateMax;

  var selectedRates = {MovieRate.liked, MovieRate.notLiked, MovieRate.okay};
  var selectedTypes = {MovieType.movie, MovieType.tv};

  bool isMoviesRequested = false;
  bool isMoviesListsRequested = false;
  bool isStarterDeckRequested = false;
  bool isCachedMoviesLoaded = false;

  setCachedUserMovies() async {
    String? storedMovies;
    try {
      storedMovies =
          await storage.read(key: 'movies').timeout(_cacheReadTimeout);
    } catch (error) {
      debugPrint('Movie cache read skipped: $error');
    }

    if (storedMovies == null) return;

    Iterable iterableMovies;
    try {
      iterableMovies = json.decode(storedMovies);
    } catch (error) {
      debugPrint('Movie cache decode skipped: $error');
      return;
    }

    if (iterableMovies.isNotEmpty) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      if (userMovies.isEmpty) cachedUserMovies = movies;
    }
  }

  Future<void> setInitialData() async {
    await Future.delayed(const Duration(milliseconds: 1));

    if (userMovies.isEmpty && cachedUserMovies.isNotEmpty) {
      setInitialUserMovies(cachedUserMovies);
    }

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

    _scheduleUserMoviesCacheWrite();
  }

  void updateUserMoviesIncognito(List<Movie> movies) {
    updateUserMovies(movies, true);

    setGenres();

    refreshMovies();
    refreshDates();
  }

  void updateUserMovies(List<Movie> userMovies, bool shouldSetRate) {
    List<Movie> updatedUserMovies = [];

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
    String? storedPersonalMoviesLists;
    try {
      storedPersonalMoviesLists = await storage
          .read(key: 'personalMoviesLists')
          .timeout(_cacheReadTimeout);
    } catch (error) {
      debugPrint('Personal movies list cache read skipped: $error');
    }

    if (storedPersonalMoviesLists != null) {
      var personalMoviesListValue =
          getMoviesListFromJson(storedPersonalMoviesLists);

      if (personalMoviesListValue != null) {
        setPersonalMoviesLists(personalMoviesListValue);
      }
    }
  }

  getMoviesListFromJson(String jsonString) {
    Iterable iterableMoviesLists;
    try {
      iterableMoviesLists = json.decode(jsonString);
    } catch (error) {
      debugPrint('Movies list cache decode skipped: $error');
      return null;
    }
    List<MoviesList> moviesLists = [];

    if (iterableMoviesLists.isNotEmpty) {
      moviesLists = iterableMoviesLists.map((model) {
        return MoviesList.fromJson(model);
      }).toList();
    }

    return moviesLists;
  }

  Future<void> _discardLegacyExternalListCache() async {
    try {
      await storage.delete(key: 'externalMoviesLists');
    } catch (error) {
      debugPrint('Legacy external list cache cleanup skipped: $error');
    }
  }

  void _scheduleUserMoviesCacheWrite() {
    _movieCacheWriteTimer?.cancel();
    _movieCacheWriteTimer = Timer(_movieCacheWriteDebounce, () {
      final moviesSnapshot = List<Movie>.of(userMovies);
      unawaited(_writeUserMoviesCache(moviesSnapshot));
    });
  }

  Future<void> _writeUserMoviesCache(List<Movie> movies) async {
    try {
      await storage.write(key: 'movies', value: jsonEncode(movies));
    } catch (error) {
      debugPrint('Movie cache write skipped: $error');
    }
  }

  void _schedulePersonalMoviesListsCacheWrite(List<MoviesList> lists) {
    _personalListsCacheWriteTimer?.cancel();
    _personalListsCacheWriteTimer = Timer(_movieCacheWriteDebounce, () {
      final listsSnapshot = List<MoviesList>.of(lists);
      unawaited(_writePersonalMoviesListsCache(listsSnapshot));
    });
  }

  Future<void> _writePersonalMoviesListsCache(List<MoviesList> lists) async {
    try {
      await storage.write(
        key: 'personalMoviesLists',
        value: jsonEncode(lists),
      );
    } catch (error) {
      debugPrint('Personal movies list cache write skipped: $error');
    }
  }

  setInitialMoviesLists(List<MoviesList> moviesLists) async {
    isMoviesListsRequested = true;

    final externalLists = moviesLists
        .where((list) => list.movieListType == MovieListType.external)
        .toList();
    final personalLists = moviesLists
        .where((list) => list.movieListType == MovieListType.personal)
        .toList();

    setExternalMoviesLists(externalLists);
    setPersonalMoviesLists(personalLists);

    unawaited(_discardLegacyExternalListCache());
    _schedulePersonalMoviesListsCacheWrite(personalLists);
  }

  setInitialMoviesListsIncognito(List<MoviesList> moviesLists) async {
    isMoviesListsRequested = true;

    final externalLists = moviesLists
        .where((list) => list.movieListType == MovieListType.external)
        .toList();

    setExternalMoviesLists(externalLists);

    unawaited(_discardLegacyExternalListCache());

    notifyListeners();
  }

  void setStarterDeckMovies(List<Movie> movies) {
    starterDeckMovies = movies;
    isStarterDeckRequested = true;

    notifyListeners();
  }

  setExternalMoviesLists(List<MoviesList> moviesLists) {
    externalMoviesLists = getMappedMoviesList(moviesLists);
  }

  setPersonalMoviesLists(List<MoviesList> moviesLists) {
    personalMoviesLists = getMappedMoviesList(moviesLists);

    notifyListeners();
  }

  getMappedMoviesList(List<MoviesList> moviesLists) {
    var lists = moviesLists.map((ml) {
      final movies = ml.listMovies.map((movie) {
        final userMovie = userMovies.where((um) => um.id == movie.id);

        if (userMovie.isNotEmpty) {
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
    personalMoviesLists.add(MoviesList(
        name: listName,
        movieListType: MovieListType.personal,
        order: order,
        listMovies: []));

    _schedulePersonalMoviesListsCacheWrite(personalMoviesLists);

    notifyListeners();
  }

  renameMoviesList(String oldName, String newName) async {
    final list =
        personalMoviesLists.singleWhere((element) => element.name == oldName);

    list.name = newName;

    _schedulePersonalMoviesListsCacheWrite(personalMoviesLists);

    notifyListeners();
  }

  removeMoviesList(String listName) {
    personalMoviesLists = personalMoviesLists
        .where((element) => element.name != listName)
        .toList();

    _schedulePersonalMoviesListsCacheWrite(personalMoviesLists);

    notifyListeners();
  }

  addMovieToPersonalList(String listName, Movie movie) {
    final list =
        personalMoviesLists.singleWhere((element) => element.name == listName);

    list.listMovies.add(movie);

    _schedulePersonalMoviesListsCacheWrite(personalMoviesLists);

    notifyListeners();
  }

  removeMovieFromPersonalList(String listName, Movie movie) {
    final list =
        personalMoviesLists.singleWhere((element) => element.name == listName);

    removeMovieFromList(movie, list.listMovies, MyGlobals.personalListsKey);

    _schedulePersonalMoviesListsCacheWrite(personalMoviesLists);

    notifyListeners();
  }

  setGenres() {
    if (genres.isNotEmpty) {
      genres.clear();
    }

    var genresList = [];

    for (var element in userMovies) {
      genresList.addAll(element.genres);
    }

    genresList.sort();

    for (var element in genresList) {
      if (!genres.any((genre) => genre.value == element)) {
        genres.add(DropdownMenuItem(
          value: element,
          child: Text(element),
        ));
      }
    }
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
    selectViewedRate(MovieRate.liked);
  }

  changeOkayOnlyFilter() {
    selectViewedRate(MovieRate.okay);
  }

  changeNotLikedOnlyFilter() {
    selectViewedRate(MovieRate.notLiked);
  }

  selectAllViewedRates() {
    selectedRates = {MovieRate.liked, MovieRate.notLiked, MovieRate.okay};
    likedOnly = false;
    okayOnly = false;
    notLikedOnly = false;

    refreshMovies();
  }

  selectViewedRate(int movieRate) {
    selectedRates = {movieRate};
    likedOnly = movieRate == MovieRate.liked;
    okayOnly = movieRate == MovieRate.okay;
    notLikedOnly = movieRate == MovieRate.notLiked;

    refreshMovies();
  }

  changeRateFilter(int movieRate) {
    if (selectedRates.contains(movieRate)) {
      if (selectedRates.length > 1) {
        selectedRates.remove(movieRate);
      }
    } else {
      selectedRates.add(movieRate);
    }

    likedOnly =
        selectedRates.length != 3 && selectedRates.contains(MovieRate.liked);
    okayOnly =
        selectedRates.length != 3 && selectedRates.contains(MovieRate.okay);
    notLikedOnly =
        selectedRates.length != 3 && selectedRates.contains(MovieRate.notLiked);

    refreshMovies();
  }

  changeDateFromFilter(DateTime value) {
    dateFrom = value;

    refreshMovies();
  }

  changeDateToFilter(DateTime value) {
    dateTo = value;

    refreshMovies();
  }

  changeGenreFilter(String? genre) {
    selectedGenre = genre;

    refreshMovies();
  }

  isAnyFilterSelected() {
    return moviesOnly ||
        tvOnly ||
        (!isWatchlist() && selectedRates.length != 3) ||
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
    okayOnly = false;
    selectedGenre = null;

    selectedRates = {MovieRate.liked, MovieRate.notLiked, MovieRate.okay};
    selectedTypes = {MovieType.movie, MovieType.tv};

    refreshMovies();
  }

  bool isDateToSelected() {
    return dateTo != null && dateTo?.difference(dateMax!).inDays != 0;
  }

  bool isDateFromSelected() {
    return dateFrom != null &&
        dateFrom!
                .difference(
                    dateMin!.subtract(const Duration(hours: 23, minutes: 59)))
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
    var moviesToAdd = [];
    var moviesToRemove = [];

    for (var movie in actualMoviesList) {
      if (!moviesList.any((m) => m.id == movie.id)) {
        moviesToAdd.add(movie);
      }
    }

    for (var movie in moviesList) {
      if (!actualMoviesList.any((m) => m.id == movie.id)) {
        moviesToRemove.add(movie);
      }
    }

    for (var movie in moviesToRemove) {
      removeMovieFromList(movie, moviesList, key);
    }

    for (var movie in moviesToAdd) {
      addMovieToList(movie, moviesList, key, actualMoviesList.indexOf(movie));
    }
  }

  List<Movie> getWatchlistMovies() {
    var result = userMovies
        .where((movie) =>
            movie.movieRate == MovieRate.addedToWatchlist &&
            (selectedTypes.isEmpty ||
                selectedTypes.contains(movie.movieType)) &&
            (selectedGenre == null || movie.genres.contains(selectedGenre)))
        .toList();

    return result;
  }

  List<Movie> getViewedMovies() {
    List<Movie> allViewedMovies = getAllViewedMovies();

    if (allViewedMovies.isEmpty) return [];

    List<Movie> filteredMovies;

    if (isDateFromSelected() || isDateToSelected()) {
      filteredMovies = allViewedMovies
          .where((movie) =>
              movie.updated!
                  .isAfter(dateFrom!.subtract(const Duration(minutes: 1))) &&
              movie.updated!.isBefore(dateTo!.add(const Duration(days: 1))))
          .toList();
    } else {
      filteredMovies = allViewedMovies;
    }

    return filteredMovies.toList();
  }

  void refreshDates() {
    List<Movie> allViewedMovies = userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .toList();

    if (allViewedMovies.isNotEmpty) {
      if (dateMin == dateFrom ||
          dateFrom == null ||
          dateFrom!.isBefore(allViewedMovies.last.updated!)) {
        dateFrom = allViewedMovies.last.updated;
      }

      dateMin = allViewedMovies.last.updated;

      if (dateMax == dateTo ||
          dateTo == null ||
          dateTo!.isAfter(allViewedMovies.first.updated!)) {
        dateTo = allViewedMovies.first.updated;
      }

      dateMax = allViewedMovies.first.updated;
    } else {
      dateFrom = dateMin = dateMax = dateTo = null;
    }
  }

  List<Movie> getAllViewedMovies() {
    var selectedRates = this.selectedRates;

    if (selectedRates.isEmpty) {
      selectedRates = {MovieRate.liked, MovieRate.notLiked, MovieRate.okay};
    }

    var result = userMovies
        .where((movie) =>
            (selectedTypes.isEmpty ||
                selectedTypes.contains(movie.movieType)) &&
            selectedRates.contains(movie.movieRate) &&
            (selectedGenre == null || movie.genres.contains(selectedGenre)))
        .toList();

    return result;
  }

  changeMovieRate(
      String movieId, int movieRate, bool isIncognitoMode, Movie movie,
      {bool updateListRatings = true}) async {
    Movie movieToRate;
    var foundMovies = userMovies.where((m) => m.id == movieId);

    if ((movie.actors.isNotEmpty ||
        movie.directors.isNotEmpty ||
        movie.genres.isNotEmpty)) {
      movieToRate = movie;
    } else if (foundMovies.isEmpty) {
      final moviesResponse = await serviceAgent.getMovie(movieId);
      movieToRate = Movie.fromJson(json.decode(moviesResponse.body));
    } else {
      movieToRate = foundMovies.first;
    }

    if (foundMovies.isEmpty) {
      userMovies.insert(0, movieToRate);
    }

    if (!isIncognitoMode) recalculateMovieRating(movieToRate, movieRate);

    if (MovieRate.isViewed(movieRate)) {
      addMovieToViewed(movieToRate, movieRate);
    } else if (movieRate == MovieRate.addedToWatchlist) {
      addMovieToWatchlist(movieToRate, movieRate);
    } else if (movieRate == MovieRate.notRated) {
      removeMovieRate(movieToRate);
    }

    if (updateListRatings) {
      setRateToMovieInLists(movieId, movieRate);
    }

    refreshMovies();
    refreshDates();
    setGenres();

    _scheduleUserMoviesCacheWrite();

    final userState = ServiceAgent.state;
    if (isIncognitoMode &&
        userState?.userId != null &&
        userState!.userId!.isNotEmpty) {
      unawaited(serviceAgent
          .rateMovie(movieId, userState.userId!, movieRate)
          .catchError(
              (error) => debugPrint('Guest rating sync failed: $error')));
    }
  }

  @override
  void dispose() {
    _movieCacheWriteTimer?.cancel();
    _personalListsCacheWriteTimer?.cancel();
    super.dispose();
  }

  // Future<void> updateMoviePosterPath(Movie movie, String posterPath) async {
  //   await storage.write(key: 'movies', value: jsonEncode(userMovies));
  // }

  void setRateToMovieInLists(String movieId, int rate) {
    for (var element in externalMoviesLists) {
      var movies = element.listMovies.where((element) => element.id == movieId);

      if (movies.isNotEmpty) movies.first.movieRate = rate;
    }

    for (var element in personalMoviesLists) {
      var movies = element.listMovies.where((element) => element.id == movieId);

      if (movies.isNotEmpty) movies.first.movieRate = rate;
    }
  }

  void removeMovieRate(Movie movieToRate) {
    if (MovieRate.isViewed(movieToRate.movieRate)) {
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
    if (key.currentState != null) key.currentState?.insertItem(index);

    moviesList.insert(index, movieToAdd);
  }

  void removeMovieFromList(Movie movieToRemove, List<Movie> moviesList,
      GlobalKey<AnimatedListState>? key) {
    final index = moviesList.indexOf(movieToRemove);

    if (index == -1) return;

    moviesList.removeAt(index);

    builder(context, animation) {
      return buildItem(movieToRemove, animation, context: context);
    }

    if (key?.currentState != null) {
      key?.currentState!.removeItem(index, builder);
    }
  }

  recalculateMovieRating(Movie movie, int updatedRate) {
    if (MovieRate.isPositiveVote(movie.movieRate)) movie.likedVotes -= 1;
    if (MovieRate.isNegativeVote(movie.movieRate)) movie.dislikedVotes -= 1;

    if (MovieRate.isPositiveVote(updatedRate)) movie.likedVotes += 1;
    if (MovieRate.isNegativeVote(updatedRate)) movie.dislikedVotes += 1;

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

  //Animated List area
  GlobalKey<AnimatedListState> watchlistKey = GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> viewedListKey = GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> personalListKey = GlobalKey<AnimatedListState>();
  // GlobalKey<AnimatedListState> personalListKey;

  Widget buildItem(Movie movie, Animation<double> animation,
      {bool isPremium = false, required BuildContext context}) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: MovieListItem(
          movie: movie,
          shouldRequestReview: true,
          mode: currentTabIndex == 0
              ? MovieCardMode.watchlist
              : MovieCardMode.viewed,
        ));
  }
}
