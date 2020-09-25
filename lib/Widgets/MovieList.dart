import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';

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
    final userState = Provider.of<UserState>(context);

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
            indicatorColor: Theme.of(context).accentColor,
            labelColor: Theme.of(context).accentColor,
            unselectedLabelColor: Theme.of(context).hintColor,
            tabs: [
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.queue_play_next),
                  SizedBox(
                    width: 7,
                  ),
                  Text(
                    'Watchlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              )),
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.check),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    'Viewed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              )),
            ],
          ),
        ),
        body: Container(
          color: Theme.of(context).primaryColor,
          child: TabBarView(
            children: [
              AnimatedList(
                padding: EdgeInsets.only(bottom: 90),
                key: provider.watchlistKey,
                initialItemCount: watchlistMovies.length,
                itemBuilder: (context, index, animation) {
                  if (watchlistMovies.length <= index) return null;

                  return provider.buildItem(watchlistMovies[index], animation);
                },
              ),
              Container(
                child: AnimatedList(
                  padding: EdgeInsets.only(bottom: 90),
                  key: provider.viewedListKey,
                  initialItemCount: viewedMovies.length,
                  itemBuilder: (context, index, animation) {
                    if (viewedMovies.length <= index) return null;

                    return provider.buildItem(viewedMovies[index], animation,
                        isPremium: userState.isPremium, context: context);
                  },
                ),
              )
            ],
          ),
        ),
        key: MyGlobals.scaffoldKey,
      ),
    );
  }
}
