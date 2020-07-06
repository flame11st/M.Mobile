import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'MState.dart';
import 'MovieListItem.dart';

class MovieList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MovieListState();
  }
}

class MovieListState extends State<MovieList> {

  didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MState>(context);

    return Container(
      color: Color(0xff222831),
      child: ListView(
        padding: EdgeInsets.all(10),
        children: [
          for ( final movie in provider.userMovies) MovieListItem(movie: movie)
        ],
      ),
    );
  }
}