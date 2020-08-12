import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';

//import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
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
    final List<Movie> watchlistMovies = provider.watchlistMovies;
    final List<Movie> viewedMovies = provider.viewedMovies;
    MyGlobals.scaffoldKey = new GlobalKey();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: TabBar(
            tabs: [
              Tab(
                  child: Text(
                'Watchlist',
                style: MTextStyles.TabTitle,
              )),
              Tab(
                  child: Text(
                'Viewed',
                style: MTextStyles.TabTitle,
              )),
            ],
          ),
        ),
        body: Container(
          color: Theme.of(context).primaryColor,
          child: TabBarView(
            children: [
              AnimatedList(
                padding: EdgeInsets.only(bottom: 75),
                key: provider.watchlistKey,
                initialItemCount: watchlistMovies.length,
                itemBuilder: (context, index, animation) {
                  if (watchlistMovies.length <= index) return null;

                  return provider.buildItem(watchlistMovies[index], animation);
                },
              ),
              AnimatedList(
                padding: EdgeInsets.only(bottom: 75),
                key: provider.viewedListKey,
                initialItemCount: viewedMovies.length,
                itemBuilder: (context, index, animation) {
                  if (viewedMovies.length <= index) return null;

                  return provider.buildItem(viewedMovies[index], animation);
                },
              ),
            ],
          ),
        ),
        key: MyGlobals.scaffoldKey,
      ),
    );
  }
}
