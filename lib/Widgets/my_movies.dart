import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Objects/user.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:provider/provider.dart';
import '../Helpers/route_helper.dart';
import 'movies_bottom_navigation_bar.dart';
import 'movie_list.dart';
import 'Providers/loader_state.dart';
import 'Providers/movies_state.dart';
import 'Providers/user_state.dart';
import 'recommendations_page.dart';

class MyMovies extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyMoviesState();
  }
}

class MyMoviesState extends State<MyMovies> {
  final serviceAgent = ServiceAgent();
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

    if (iterableMovies.isNotEmpty) {
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

    if (iterableMovies.isNotEmpty) {
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

    if (iterableMoviesLists.isNotEmpty) {
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

      final userInfoResponse =
          await serviceAgent.getUserInfo(userState.userId!);
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

    if (loaderState.isLoaderVisible && moviesState.userMovies.isNotEmpty) {
      loaderState.setIsLoaderVisible(false);
    }

    var additionalPadding = Platform.isIOS
        ? userState.isPremium
            ? 0.06
            : 0.08
        : 0;

    final myMoviesWidget = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AdManager.bannerVisible && AdManager.bannersReady
          ? AppBar(
              title:
                  Center(child: AdManager.getBannerWidget(AdManager.bannerAd!)),
              elevation: 0.7,
            )
          : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
      body: Stack(
        children: <Widget>[
          MovieList(),
          Align(
              alignment: Alignment.bottomCenter,
              child: MoviesBottomNavigationBar()),
          Align(
              alignment: Alignment(0.0, 0.93 - additionalPadding),
              child: SizedBox(
                  height: 65.0,
                  width: 65.0,
                  child: FittedBox(
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context).push(RouteHelper.createRoute(
                            () => RecommendationsPage()));
                      },
                      backgroundColor: Theme.of(context).indicatorColor,
                      foregroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.electric_bolt_rounded,
                        size: 35,
                      ),
                    ),
                  ))),
        ],
      ),
    );

    return myMoviesWidget;
  }
}

