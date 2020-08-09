import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/User.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'BottomNavigationBar.dart';
import 'MovieList.dart';
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

    if (moviesState.userMovies.length > 0) return;

    serviceAgent.state = userState;
    final moviesResponse = await serviceAgent.getUserMovies(userState.userId);

    Iterable iterableMovies = json.decode(moviesResponse.body);

    if (iterableMovies.length == 0) return;

    List<Movie> movies = iterableMovies.map((model) {
      return Movie.fromJson(model);
    }).toList();

    moviesState.setUserMovies(movies);
  }

  setUserInfo() async {
    final userState = Provider.of<UserState>(context);

    if (userState.user != null) return;

    serviceAgent.state = userState;
    final userInfoResponse = await serviceAgent.getUserInfo(userState.userId);
    final user = User.fromJson(json.decode(userInfoResponse.body));

    userState.user = user;
  }

  @override
  Widget build(BuildContext context) {
    setUserMovies();
    setUserInfo();

    return Scaffold(
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
                    backgroundColor: MColors.AdditionalColor,
                    foregroundColor: MColors.PrimaryColor,
                  ),
                )
          ))
        ],
      ),
    );
  }
}
