import 'dart:convert';

import 'package:flutter/material.dart';
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

    if (moviesState.isMoviesRequested) {
      return;
    }

    moviesState.setInitialData();
    moviesState.isMoviesRequested = true;

    serviceAgent.state = userState;
    final moviesResponse = await serviceAgent.getUserMovies(userState.userId);

    Iterable iterableMovies = json.decode(moviesResponse.body);

    if (iterableMovies.length != 0) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      if (userState.user != null)
        moviesState.setUserMovies(movies);
    }

    if (loaderState.isLoaderVisible) {
      loaderState.setIsLoaderVisible(false);
    }
  }

  setMoviesLists() async {
    final moviesState = Provider.of<MoviesState>(context);

    if (moviesState.isMoviesListsRequested) return;
    moviesState.isMoviesListsRequested = true;

    moviesState.setCachedMoviesLists();

    final moviesListsResponse = await serviceAgent.getMoviesLists();
    Iterable iterableMoviesLists = json.decode(moviesListsResponse.body);

    if (iterableMoviesLists.length != 0) {
      List<MoviesList> moviesLists = iterableMoviesLists.map((model) {
        return MoviesList.fromJson(model);
      }).toList();

      moviesState.setInitialMoviesLists(moviesLists);
    }
  }

  setUserInfo() async {
    final userState = Provider.of<UserState>(context);

    if (userState.userRequested) return;
    userState.userRequested = true;

    serviceAgent.state = userState;
    final userInfoResponse = await serviceAgent.getUserInfo(userState.userId);
    final user = User.fromJson(json.decode(userInfoResponse.body));

    userState.setUser(user);
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

    final myMoviesWidget = Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Stack(
        children: <Widget>[
          MovieList(),
          Align(
              alignment: Alignment.bottomCenter,
              child: MoviesBottomNavigationBar()),
          Align(
              alignment: Alignment(0.0, 0.982),
              child: Container(
                  height: 50.0,
                  width: 50.0,
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
                  )))
        ],
      ),
    );

    return userState.showTutorial ? WelcomeTutorial() : myMoviesWidget;
  }
}
