import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
//import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'MState.dart';
import 'MovieListItem.dart';
import 'Providers/MoviesState.dart';

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
    final provider = Provider.of<MoviesState>(context);
    final List<Movie> watchlistMovies = provider.getWatchlistMovies();
    final List<Movie> viewedMovies = provider.getViewedMovies();

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
//          bottomNavigationBar: BottomAppBar(
//            color: MColors.PrimaryColor,
//            child: TabBar(
//              tabs: [
//                Tab(child: Text('Watchlist', style: MTextStyles.TabTitle,)),
//                Tab(child: Text('Viewed', style: MTextStyles.TabTitle,)),
//              ],
//            ),
//          ),
        body: Container(
          color: MColors.PrimaryColor,
          child: TabBarView(
            children: [
              AnimatedList(
                padding: EdgeInsets.only(bottom: 75),
                key: provider.watchlistKey,
                initialItemCount: watchlistMovies.length,
                itemBuilder: (context, index, animation) {
                  return provider.buildItem(watchlistMovies[index], animation);
                },
              ),
              AnimatedList(
                padding: EdgeInsets.only(bottom: 75),
                key: provider.viewedListKey,
                initialItemCount: viewedMovies.length,
                itemBuilder: (context, index, animation) {
                  return provider.buildItem(viewedMovies[index], animation);
                },
              ),
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
