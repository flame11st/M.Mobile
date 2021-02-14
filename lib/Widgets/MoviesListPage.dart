import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieListType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:provider/provider.dart';
import 'MovieListItem.dart';
import 'Providers/MoviesState.dart';

class MoviesListPage extends StatefulWidget {
  final MoviesList moviesList;

  const MoviesListPage({Key key, this.moviesList}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MovieListPageState(moviesList);
  }
}

class MovieListPageState extends State<MoviesListPage> {
  MoviesList moviesList;

  MovieListPageState(MoviesList moviesList) {
    this.moviesList = moviesList;
  }

  final serviceAgent = new ServiceAgent();

  Widget buildItem(Movie movie, Animation animation) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: Column(
          children: [
            MovieListItem(
              movie: movie,
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final moviesState = Provider.of<MoviesState>(context);

    GlobalKey globalKey = new GlobalKey();

    if (ModalRoute.of(context).isCurrent && moviesList.listMovies.isNotEmpty) {
      MyGlobals.activeKey = globalKey;
    }

    GlobalKey<AnimatedListState> key = GlobalKey<AnimatedListState>();

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          moviesList.name,
          style: Theme.of(context).textTheme.headline5,
        ),
        if (moviesList.movieListType == MovieListType.personal)
          IconButton(
            icon: Icon(
              Icons.delete_forever,
              size: 25,
              color: Colors.red,
            ),
            color: Theme.of(context).cardColor,
            onPressed: () {
              moviesState.removeMoviesList(moviesList.name);

              Navigator.of(context).pop();
              
              if (!userState.isIncognitoMode) {
                serviceAgent.state = userState;

                serviceAgent.removeUserMoviesList(
                    userState.userId, moviesList.name);
              }
            },
          )
      ],
    );

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          title: headingField,
        ),
        body: Container(
          key: globalKey,
          child: AnimatedList(
            padding: EdgeInsets.only(bottom: 90),
            key: key,
            initialItemCount: moviesList.listMovies.length,
            itemBuilder: (context, index, animation) {
              if (moviesList.listMovies.length <= index) return null;

              return buildItem(moviesList.listMovies[index], animation);
            },
          ),
        ));
  }
}
