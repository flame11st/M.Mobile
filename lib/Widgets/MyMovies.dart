import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/User.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:provider/provider.dart';
import 'MoviesBottomNavigationBar.dart';
import 'MovieList.dart';
import 'Providers/LoaderState.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
import 'SearchDelegate.dart';

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

    setUserInfo();
    setUserMovies();

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
              alignment: Alignment(0.0, 0.985),
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
                        Icons.add,
                        size: 40,
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  )))
        ],
      ),
    );

    return myMoviesWidget;
  }
}
