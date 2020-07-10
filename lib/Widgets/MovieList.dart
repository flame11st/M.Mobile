import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
//import 'package:flutter_neumorphic/flutter_neumorphic.dart';
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

  Widget _buildItem(Movie movie, Animation animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: MovieListItem(movie: movie)
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MState>(context);
    final List<Movie> watchlistMovies = provider.watchlistMovies;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: MColors.PrimaryColor,
          title: TabBar(
            tabs: [
              Tab(child: Text('Watchlist', style: MTextStyles.TabTitle,)),
              Tab(child: Text('Viewed', style: MTextStyles.TabTitle,)),
              Tab(child: Text('TEST', style: MTextStyles.TabTitle,)),
            ],
          ),
        ),
        body: Container(
          color: MColors.PrimaryColor,
          child: TabBarView(
            children: [
              ListView(padding: EdgeInsets.all(10), children: [
                for (final movie in provider.watchlistMovies)
                  MovieListItem(movie: movie)
              ]),
              ListView(padding: EdgeInsets.all(10), children: [
                for (final movie in provider.viewedMovies)
                  MovieListItem(movie: movie)
              ]),
              AnimatedList(
                key: provider.listKey,
                initialItemCount: watchlistMovies.length,
                itemBuilder: (context, index, animation) {
                  return _buildItem(watchlistMovies[index], animation);
                },
              )
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
