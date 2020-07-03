import 'package:flutter/material.dart';
import 'MovieListItem.dart';

class MovieList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MovieListState();
  }
}

class MovieListState extends State<MovieList> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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