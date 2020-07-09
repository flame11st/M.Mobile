import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'BottomNavigationBar.dart';
import 'MState.dart';
import 'MovieList.dart';

class MyMovies extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyMoviesState();
  }
}

class MyMoviesState extends State<MyMovies> {
  final serviceAgent = new ServiceAgent();

//  didChangeDependencies() {
//    super.didChangeDependencies();
//    setUserMovies();
//  }

  setUserMovies() async {
    final provider = Provider.of<MState>(context);

    if(provider.userMovies.length > 0) return;

    serviceAgent.state = provider;
    final moviesResponse = await serviceAgent.getUserMovies(provider.userId);

    Iterable iterableMovies = json.decode(moviesResponse.body);
    List<Movie> movies = iterableMovies.map((model) {
      return Movie.fromJson(model);
    }).toList();

    provider.setUserMovies(movies);
  }

  @override
  Widget build(BuildContext context) {
    setUserMovies();

    return Scaffold(
//      appBar: AppBar(
//        backgroundColor: MColors.PrimaryColor,
//      ),
      body: MovieList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Floating action button pressed');
        },
        child: const Icon(Icons.add),
        backgroundColor: MColors.FontsColor,
        foregroundColor: MColors.PrimaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: MColors.PrimaryColor,
      bottomNavigationBar: MoviesBottomNavigationBar(),
    );
  }
}