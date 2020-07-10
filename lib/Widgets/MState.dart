import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Objects/Movie.dart';
import '../Services/ServiceAgent.dart';

class MState with ChangeNotifier {
  MState() {
    setInitialData();
  }

  final storage = new FlutterSecureStorage();
  final serviceAgent = new ServiceAgent();
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  bool isUserAuthorized = false;
  bool isAppLoaded = false;
  String userName = '';
  String userId = '';
  String token = '';
  String refreshToken = '';
  List<Movie> userMovies = new List<Movie>();
  List<Movie> watchlistMovies = new List<Movie>();
  List<Movie> viewedMovies = new List<Movie>();

  void setInitialData() async {
    var storedToken = await storage.read(key: 'token');
    var storedRefreshToken = await storage.read(key: 'refreshToken');
    var storedUserId = await storage.read(key: 'userId');
    var storedUserName = await storage.read(key: 'userName');

    this.token = storedToken;
    this.refreshToken = storedRefreshToken;
    this.userId = storedUserId;
    this.userName = storedUserName;

    serviceAgent.state = this;
    var authorizationResponse = await serviceAgent.checkAuthorization();
    if (authorizationResponse.statusCode == 200) {
      isUserAuthorized = true;
    }

    isAppLoaded = true;

    notifyListeners();
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    token = accessToken;
    this.refreshToken = refreshToken;

    await storage.write(key: 'token', value: token);
    await storage.write(key: 'refreshToken', value: refreshToken);
  }

  void setUserMovies(List<Movie> userMovies) async {
//        this.userMovies = userMovies;
    this.watchlistMovies = userMovies.where((movie) =>
      movie.movieRate == MovieRate.addedToWatchlist).toList();

    this.viewedMovies = userMovies.where((movie) =>
      movie.movieRate == MovieRate.liked || movie.movieRate == MovieRate.notLiked)
      .toList();

    notifyListeners();
  }

  Future<void> setInitialUserData(String token, String refreshToken,
      String userId, String userName) async {
    this.token = token;
    this.refreshToken = refreshToken;
    this.userId = userId;
    this.userName = userName;
    this.isUserAuthorized = true;

    notifyListeners();

    await storage.write(key: 'token', value: token);
    await storage.write(key: 'userId', value: userId);
    await storage.write(key: 'userName', value: userName);
    await storage.write(key: 'refreshToken', value: refreshToken);
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

  //TODO: Implement AnimatedList logic
  changeMovieRate(String movieId, int movieRate) async {
    if (movieId == null) return;

    await serviceAgent.rateMovie(movieId, userId, movieRate);

    if (movieRate == MovieRate.liked || movieRate == MovieRate.notLiked) {
      final foundMovies = this.watchlistMovies.where((movie) => movie.id == movieId);
      final index = watchlistMovies.indexOf(foundMovies.first);

      this.viewedMovies.add(foundMovies.first);
      this.watchlistMovies.removeAt(index);
      
      listKey.currentState.removeItem(index, (context, animation) => null);
      
    } else if (movieRate == MovieRate.addedToWatchlist) {
      final foundMovies = this.viewedMovies.where((movie) => movie.id == movieId);

      this.watchlistMovies.add(foundMovies.first);
      this.viewedMovies.remove(foundMovies.first);
    }

//    final foundMovies = this.userMovies.where((movie) => movie.id == movieId);
//
//    if (foundMovies.length != 0) {
//      foundMovies.first.movieRate = movieRate;
//    }
/*
      await new Future.delayed(const Duration(seconds: 2));*/

    notifyListeners();
  }
}