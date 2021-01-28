import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Variables/Variables.dart';
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

  // Widget buildItem(Movie movie, Animation animation, String imageUrl) {
  //   return SizeTransition(
  //       key: ObjectKey(movie),
  //       sizeFactor: animation,
  //       child: Column(
  //         children: [
  //           MovieListItem(
  //             movie: movie,
  //             // imageUrl: imageUrl,
  //           )
  //         ],
  //       ));
  // }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);

    MyGlobals.scaffoldMoviesListsKey = new GlobalKey();
    GlobalKey<AnimatedListState> key = GlobalKey<AnimatedListState>();

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.format_list_bulleted,
              size: 25,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              moviesList.name,
              style: Theme.of(context).textTheme.headline5,
            )
          ],
        ),
      ],
    );

    // MyGlobals.scaffoldKey = new GlobalKey();

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          title: headingField,
        ),
        body: Container(
          key: MyGlobals.scaffoldMoviesListsKey,
          child: AnimatedList(
            padding: EdgeInsets.only(bottom: 90),
            key: key,
            initialItemCount: moviesList.listMovies.length,
            itemBuilder: (context, index, animation) {
              if (moviesList.listMovies.length <= index) return null;

              return buildItem(moviesList.listMovies[index], animation);
              // return buildItem(moviesList.listMovies[index], animation,
              //     moviesState.imageBaseUrl);
            },
          ),
        ));
  }
}
