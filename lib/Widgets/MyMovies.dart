import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'BottomNavigationBar.dart';
import 'MState.dart';
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

    if (moviesState.watchlistMovies.length > 0 ||
        moviesState.viewedMovies.length > 0) return;

    serviceAgent.state = userState;
    final moviesResponse = await serviceAgent.getUserMovies(userState.userId);

    Iterable iterableMovies = json.decode(moviesResponse.body);
    List<Movie> movies = iterableMovies.map((model) {
      return Movie.fromJson(model);
    }).toList();

    moviesState.setUserMovies(movies);
  }

  @override
  Widget build(BuildContext context) {
    setUserMovies();

    return Scaffold(
//      appBar: AppBar(
//        backgroundColor: MColors.PrimaryColor,
//      ),
      body: Stack(
        children: <Widget>[
          MovieList(),
          Align(
              alignment: Alignment.bottomCenter,
              child: MoviesBottomNavigationBar()),
          Align(
            alignment: Alignment(0.0, 0.97),
            child: Container(
                height: 60.0,
                width: 60.0,
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
                      size: 35,
                    ),
                    backgroundColor: MColors.AdditionalColor,
                    foregroundColor: MColors.PrimaryColor,
                  ),
                )
          ))
        ],
      ),
//
//      floatingActionButton: FloatingActionButton(
//        onPressed: () {
//          print('Floating action button pressed');
//        },
//        child: const Icon(
//          Icons.add,
//          size: 35,
//        ),
//        backgroundColor: MColors.AdditionalColor,
//        foregroundColor: MColors.PrimaryColor,
//      ),
//      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//      backgroundColor: Colors.transparent,
//      bottomNavigationBar: MoviesBottomNavigationBar(),
    );
  }
}
