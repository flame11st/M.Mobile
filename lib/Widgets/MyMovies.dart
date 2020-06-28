import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';
import 'MovieList.dart';

class MyMovies extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyMoviesState();
  }
}

class MyMoviesState extends State<MyMovies> {
  @override
  Widget build(BuildContext context) {
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