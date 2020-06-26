import 'package:flutter/material.dart';
import 'MovieListItem.dart';

class MovieList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ListView(
      padding: EdgeInsets.all(20),
      children: <Widget>[
        MovieListItem(),
        MovieListItem(),
        MovieListItem(),
        MovieListItem()
      ],
    );
  }
}