import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Objects/User.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:provider/provider.dart';
import 'MoviesBottomNavigationBar.dart';
import 'MovieList.dart';
import 'Providers/LoaderState.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
import 'SearchDelegate.dart';
import 'WelcomeTutorial.dart';

class MyMovies extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyMoviesState();
  }
}

class MyMoviesState extends State<MyMovies> {
  final serviceAgent = new ServiceAgent();

  setUserMovies() async {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);
    final loaderState = Provider.of<LoaderState>(context);

    serviceAgent.state = userState;

    if (moviesState.isMoviesRequested) {
      return;
    }

    moviesState.setInitialData();
    moviesState.isMoviesRequested = true;

    if (userState.isIncognitoMode) {
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }

      setIncognitoUserMovies(moviesState);

      return;
    }

    final moviesResponse = await serviceAgent.getUserMovies(userState.userId);

    Iterable iterableMovies = json.decode(moviesResponse.body);

    if (iterableMovies.length != 0) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      if (userState.user != null)
        moviesState.setUserMovies(movies);
    } else {
      moviesState.setUserMovies(new List<Movie>());
    }

    if (loaderState.isLoaderVisible) {
      loaderState.setIsLoaderVisible(false);
    }
  }

  setIncognitoUserMovies(MoviesState moviesState) async {
    final moviesIds = moviesState.cachedUserMovies.map((e) => e.id).toList();

    var encodedIds = json.encode(moviesIds);

    final moviesResponse = await serviceAgent.getMoviesByIds(encodedIds);

    Iterable iterableMovies = json.decode(moviesResponse.body);

    if (iterableMovies.length != 0) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      moviesState.updateUserMovies(movies, true);
    }
  }

  setMoviesLists() async {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    if (moviesState.isMoviesListsRequested) return;
    moviesState.isMoviesListsRequested = true;

    final moviesListsResponse = await serviceAgent.getMoviesLists(userState.userId);

    Iterable iterableMoviesLists = json.decode(moviesListsResponse.body);

    if (iterableMoviesLists.length != 0) {
      List<MoviesList> moviesLists = iterableMoviesLists.map((model) {
        var list = json.decode(model);
        return MoviesList.fromJson(list);
      }).toList();

      if (userState.isIncognitoMode) {
        moviesState.setInitialMoviesListsIncognito(moviesLists);
      } else {
        moviesState.setInitialMoviesLists(moviesLists);
      }
    }
  }

  setUserInfo() async {
    final userState = Provider.of<UserState>(context);
    final moviesState = Provider.of<MoviesState>(context);

    if (userState.userRequested) return;

    userState.userRequested = true;

    if (userState.userId != null && userState.userId.isNotEmpty) {
      serviceAgent.state = userState;

      if (userState.isIncognitoMode) {
        userState.isIncognitoMode = false;

        var movies = moviesState.userMovies;

        movies.forEach((movie) async {
          await serviceAgent.rateMovie(movie.id, userState.userId, movie.movieRate);
        });

        if (userState.premiumPurchasedIncognito) {
          await serviceAgent.setUserPremiumPurchased(userState.userId, true);
        }
      }

      final userInfoResponse = await serviceAgent.getUserInfo(userState.userId);
      final user = User.fromJson(json.decode(userInfoResponse.body));

      userState.setUser(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final loaderState = Provider.of<LoaderState>(context);
    final userState = Provider.of<UserState>(context);

    setUserInfo();
    setUserMovies();
    setMoviesLists();

    if (loaderState.isLoaderVisible && moviesState.userMovies.length > 0) {
      loaderState.setIsLoaderVisible(false);
    }

    var additionalPadding = Platform.isIOS ? 0.06 : 0;

    final myMoviesWidget = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AdManager.bannerVisible && AdManager.bannersReady ? AppBar(
        title:  AdManager.getBannerWidget(AdManager.bannerAd)
      ) : PreferredSize(preferredSize: Size(0,0), child: Container()),
      body: Stack(
        children: <Widget>[
          MovieList(),
          Align(
              alignment: Alignment.bottomCenter,
              child: MoviesBottomNavigationBar()),
          Align(
              alignment: Alignment(0.0, 0.97 - additionalPadding),
              child: Container(
                  height: 55.0,
                  width: 55.0,
                  child: FittedBox(
                    child: FloatingActionButton(
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: MSearchDelegate(),
                        );
                      },
                      child: const Icon(
                        Icons.search,
                        size: 35,
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ))),
        ],
      ),
    );

    return userState.showTutorial ? WelcomeTutorial() : myMoviesWidget;
  }
}
