import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Objects/User.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:provider/provider.dart';
import '../Helpers/RouteHelper.dart';
import 'MoviesBottomNavigationBar.dart';
import 'MovieList.dart';
import 'Providers/LoaderState.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
import 'RecommendationsPage.dart';
import 'SearchDelegate.dart';

class MyMovies extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyMoviesState();
  }
}

class MyMoviesState extends State<MyMovies> {
  final serviceAgent = new ServiceAgent();
  bool userDataRequested = false;

  setUserMovies() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final loaderState = Provider.of<LoaderState>(context, listen: false);

    if (userState.isIncognitoMode) {
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }

      moviesState.setInitialData();
      setIncognitoUserMovies(moviesState);

      return;
    }

    final moviesResponse = await serviceAgent.getUserMovies(userState.userId!);

    print("Movies loaded");
    Iterable iterableMovies = json.decode(moviesResponse.body);

    if (iterableMovies.length != 0) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      moviesState.setUserMovies(movies);
    } else {
      moviesState.setUserMovies([]);
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

      moviesState.updateUserMoviesIncognito(movies);
    }
  }

  setMoviesLists() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    final moviesListsResponse =
        await serviceAgent.getMoviesLists(userState.userId!);

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

  Future<void> setUserInfo() async {
    final userState = Provider.of<UserState>(context);
    final moviesState = Provider.of<MoviesState>(context);

    if (userState.userId != null && userState.userId!.isNotEmpty) {
      if (userState.isIncognitoMode) {
        userState.isIncognitoMode = false;

        var movies = moviesState.userMovies;

        movies.forEach((movie) async {
          await serviceAgent.rateMovie(
              movie.id, userState.userId!, movie.movieRate);
        });

        if (userState.premiumPurchasedIncognito) {
          await serviceAgent.setUserPremiumPurchased(userState.userId!, true);
        }
      }

      final userInfoResponse = await serviceAgent.getUserInfo(userState.userId!);
      final user = User.fromJson(json.decode(userInfoResponse.body));

      userState.setUser(user);
    }
  }

  Future<void> SetUserData() async {
    await setUserInfo();
    setUserMovies();
    setMoviesLists();
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final loaderState = Provider.of<LoaderState>(context);
    final userState = Provider.of<UserState>(context);

    if (!userDataRequested) {
      SetUserData();

      userDataRequested = true;
    }

    if (loaderState.isLoaderVisible && moviesState.userMovies.length > 0) {
      loaderState.setIsLoaderVisible(false);
    }

    var additionalPadding = Platform.isIOS ? 0.06 : 0;

    final myMoviesWidget = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AdManager.bannerVisible && AdManager.bannersReady
          ? AppBar(
              title:
                  Center(child: AdManager.getBannerWidget(AdManager.bannerAd!)),
              elevation: 0.7,
            )
          : PreferredSize(preferredSize: Size(0, 0), child: Container()),
      body: Stack(
        children: <Widget>[
          MovieList(),
          Align(
              alignment: Alignment.bottomCenter,
              child: MoviesBottomNavigationBar()),
          Align(
              alignment: Alignment(0.0, 0.93 - additionalPadding),
              child: Container(
                  height: 65.0,
                  width: 65.0,
                  child: FittedBox(
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(RouteHelper.createRoute(() => RecommendationsPage()));
                      },
                      child: const Icon(
                        Icons.electric_bolt_rounded,
                        size: 35,
                      ),
                      backgroundColor: Theme.of(context).indicatorColor,
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ))),
        ],
      ),
    );

    return myMoviesWidget;
  }
}
