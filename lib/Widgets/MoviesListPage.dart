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
import 'Shared/MDialog.dart';

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
                moviesList:
                    this.moviesList.movieListType == MovieListType.personal
                        ? this.moviesList
                        : null)
          ],
        ));
  }

  void removeListButtonClicked() {
    var mDialog = new MDialog(
        context: context,
        content: Text(
            'Are You really want to remove your list "${moviesList.name}"?'),
        firstButtonText: 'Yes, remove',
        firstButtonCallback: () {
          removeList();
        },
        secondButtonText: 'Cancel',
        secondButtonCallback: () {});

    mDialog.openDialog();
  }

  void removeList() {
    final userState = Provider.of<UserState>(context);
    final moviesState = Provider.of<MoviesState>(context);

    moviesState.removeMoviesList(moviesList.name);

    Navigator.of(context).pop();

    if (!userState.isIncognitoMode) {
      serviceAgent.state = userState;

      serviceAgent.removeUserMoviesList(userState.userId, moviesList.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey globalKey = new GlobalKey();

    if (ModalRoute.of(context).isCurrent && moviesList.listMovies.isNotEmpty) {
      MyGlobals.activeKey = globalKey;
    }

    MyGlobals.personalListsKey = GlobalKey<AnimatedListState>();

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
            child: Text(
          moviesList.name,
          style: Theme.of(context).textTheme.headline5,
        )),
        if (moviesList.movieListType == MovieListType.personal)
          IconButton(
            icon: Icon(
              Icons.delete_forever,
              size: 25,
              color: Colors.red,
            ),
            color: Theme.of(context).cardColor,
            onPressed: () {
              removeListButtonClicked();
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
            key: MyGlobals.personalListsKey,
            initialItemCount: moviesList.listMovies.length,
            itemBuilder: (context, index, animation) {
              if (moviesList.listMovies.length <= index) return null;

              return buildItem(moviesList.listMovies[index], animation);
            },
          ),
        ));
  }
}
