import 'package:flutter/material.dart';
import 'MovieListItem.dart';

class MovieList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xff222831),
      child: ListView(
        padding: EdgeInsets.all(20),
        children: <Widget>[
          MovieListItem(),
          MovieListItem(),
          MovieListItem(),
          MovieListItem()
        ],
      ),
    );
  }
}