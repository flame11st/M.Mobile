import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieListType.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/MSnackBar.dart';
import 'package:provider/provider.dart';
import 'MovieListItem.dart';
import 'Providers/MoviesState.dart';
import 'Shared/MButton.dart';
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
  final nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
                shouldRequestReview: false,
                movie: movie,
                moviesList:
                    this.moviesList.movieListType == MovieListType.personal
                        ? this.moviesList
                        : null)
          ],
        ));
  }

  void removeListButtonClicked() {
    Navigator.of(context).pop();

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

  void renameListButtonClicked() {
    Navigator.of(context).pop();

    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    nameController.text = moviesList.name;

    showDialog<String>(
        context: context,
        builder: (BuildContext context1) => AlertDialog(
              contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headline5,
              content: Container(
                  height: 90,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(0),
                  child: Form(
                    key: _formKey,
                    child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: Theme.of(context).accentColor),
                        child: TextFormField(
                          validator: (value) => nameController.text.isEmpty
                              ? "Please enter name"
                              : moviesState.personalMoviesLists.any((element) =>
                                      element.name == nameController.text &&
                                      element != moviesList)
                                  ? "List with the same name already exists"
                                  : null,
                          controller: nameController,
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              labelText: "Enter new list name",
                              hintStyle: Theme.of(context).textTheme.headline5),
                        )),
                  )),
              actions: [
                MButton(
                  active: true,
                  text: 'Rename',
                  parentContext: context,
                  onPressedCallback: () async {
                    if (_formKey.currentState != null &&
                        _formKey.currentState.validate()) {
                      moviesState.renameMoviesList(
                          moviesList.name, nameController.text);

                      MSnackBar.showSnackBar(
                          'The List renamed to "${nameController.text}"', true);

                      Navigator.of(context1).pop();

                      if (!userState.isIncognitoMode) {
                        serviceAgent.state = userState;

                        await serviceAgent.renameUserMoviesList(
                            userState.userId,
                            moviesList.name,
                            nameController.text);
                      }

                      nameController.clear();
                    }
                  },
                ),
                SizedBox(
                  width: 10,
                ),
                MButton(
                  active: true,
                  text: 'Cancel',
                  parentContext: context,
                  onPressedCallback: () => Navigator.of(context1).pop(),
                )
              ],
            ));
  }

  void removeList() {
    final userState = Provider.of<UserState>(context, listen: false);
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    moviesState.removeMoviesList(moviesList.name);

    Navigator.of(context).pop();

    if (!userState.isIncognitoMode) {
      serviceAgent.removeUserMoviesList(userState.userId, moviesList.name);
    }
  }

  Widget getBody() {
    Widget widgetToReturn = moviesList.listMovies.isNotEmpty
        ? AnimatedList(
            padding: EdgeInsets.only(bottom: 90),
            key: MyGlobals.personalListsKey,
            initialItemCount: moviesList.listMovies.length,
            itemBuilder: (context, index, animation) {
              if (moviesList.listMovies.length <= index) return null;

              return buildItem(moviesList.listMovies[index], animation);
            },
          )
        : Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "You haven't added any items to this list.\n"
              "Please use Search or Check General Movies Lists to find items which you want to add.",
              style: TextStyle(fontSize: 17, height: 2),
            ));

    return widgetToReturn;
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);

    if (serviceAgent.state == null) {
      serviceAgent.state = userState;
    }

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
          PopupMenuButton(
            padding: EdgeInsets.zero,
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                  child: GestureDetector(
                      onTap: () => removeListButtonClicked(),
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_forever,
                          size: 25,
                          color: Theme.of(context).accentColor,
                        ),
                        title: Text("Remove List"),
                      ))),
              PopupMenuDivider(
                height: AdManager.bannerVisible ? 50 : 5,
              ),
              PopupMenuItem<String>(
                  child: GestureDetector(
                      onTap: () => renameListButtonClicked(),
                      child: ListTile(
                        leading: Icon(
                          Icons.edit,
                          size: 25,
                          color: Theme.of(context).accentColor,
                        ),
                        title: Text("Change List Name"),
                      ))),
            ],
          ),
      ],
    );

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          title: headingField,
        ),
        body: Container(
            key: globalKey,
            padding: EdgeInsets.only(top: AdManager.bannerVisible ? 65 : 0),
            child: getBody()));
  }
}
