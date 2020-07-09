import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:mmobile/Variables/Variables.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: MColors.PrimaryColor,
          title: TabBar(
            tabs: [
              Tab(child: Text('Watchlist', style: MTextStyles.TabTitle,)),
              Tab(child: Text('Viewed', style: MTextStyles.TabTitle,)),
            ],
          ),
        ),
        body: Container(
          color: MColors.PrimaryColor,
          child: TabBarView(
            children: [
              ListView(padding: EdgeInsets.all(10), children: [
                for (final movie in provider.getWatchlistMovies())
                  MovieListItem(movie: movie)
              ]),
              ListView(padding: EdgeInsets.all(10), children: [
                for (final movie in provider.getViewedMovies())
                  MovieListItem(movie: movie)
              ]),
            ],
          ),
        )
      ),
    );

//      Container(
//      margin: EdgeInsets.only(top: 20),
//      color: MColors.PrimaryColor,
//      child: ListView(
//        padding: EdgeInsets.all(10),
//        children: [
//          for ( final movie in provider.userMovies) MovieListItem(movie: movie)
//        ],
//      ),
//    );
  }
}
