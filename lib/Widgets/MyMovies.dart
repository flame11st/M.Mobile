import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
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

  didChangeDependencies() {
    super.didChangeDependencies();
    setUserMovies();
  }

  setUserMovies() async {
    final provider = Provider.of<MState>(context);
    serviceAgent.state = provider;
    final moviesResponse = await serviceAgent.getUserMovies(provider.userId);

    Iterable iterableMovies = json.decode(moviesResponse.body);
    List<Movie> movies = iterableMovies.map((model) {
      return Movie.fromJson(model);
    }).toList();

    provider.setUserMovies(movies);
    var x = '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MState>(context);


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff222831),
      ),
      body: MovieList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Floating action button pressed');
        },
        child: const Icon(Icons.add),
        backgroundColor: Color(0xffeeeeee),
        foregroundColor: Color(0xff222831),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: Color(0xff222831),
      bottomNavigationBar: MoviesBottomNavigationBar(),
    );
  }
}