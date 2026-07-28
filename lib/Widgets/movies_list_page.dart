import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Helpers/route_helper.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:provider/provider.dart';
import 'movie_list_item.dart';
import 'Providers/movies_state.dart';
import 'search_page.dart';
import 'Shared/md3_ui.dart';
import 'Shared/m_button.dart';
import 'Shared/m_dialog.dart';
import 'Shared/m_movies_animated_list.dart';

class MoviesListPage extends StatefulWidget {
  final MoviesList moviesList;

  const MoviesListPage({super.key, required this.moviesList});

  @override
  State<StatefulWidget> createState() {
    return MovieListPageState(moviesList);
  }
}

class MovieListPageState extends State<MoviesListPage> {
  late MoviesList moviesList;
  final nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  MovieListPageState(MoviesList moviesList) {
    this.moviesList = moviesList;
  }

  final serviceAgent = ServiceAgent();

  Widget buildItem(Movie movie, Animation<double> animation,
      {bool isPremium = false, required BuildContext context}) {
    return SizeTransition(
        key: ObjectKey(movie),
        sizeFactor: animation,
        child: MovieListItem(
            shouldRequestReview: false,
            movie: movie,
            moviesList: moviesList.movieListType == MovieListType.personal
                ? moviesList
                : null,
            mode: moviesList.movieListType == MovieListType.personal
                ? MovieCardMode.personalList
                : MovieCardMode.browse));
  }

  void removeListButtonClicked() {
    Navigator.of(context).pop();

    var mDialog = MDialog(
        context: context,
        content: Text(
            'Remove "${moviesList.name}"? This deletes the list, but keeps the movies in your watch history.'),
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
              contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headlineSmall,
              content: Container(
                  height: 90,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(0),
                  child: Form(
                    key: _formKey,
                    child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: Theme.of(context).indicatorColor),
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
                              contentPadding:
                                  const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              labelText: "Enter new list name",
                              hintStyle:
                                  Theme.of(context).textTheme.headlineSmall),
                        )),
                  )),
              actions: [
                MButton(
                  active: true,
                  text: 'Rename',
                  parentContext: context,
                  onPressedCallback: () async {
                    if (_formKey.currentState != null &&
                        _formKey.currentState!.validate()) {
                      final oldName = moviesList.name;
                      final newName = nameController.text;
                      moviesState.renameMoviesList(oldName, newName);

                      MSnackBar.showSnackBar(
                          'The List renamed to "$newName"', true);

                      Navigator.of(context1).pop();

                      if (userState.userId != null &&
                          userState.userId!.isNotEmpty) {
                        await serviceAgent.renameUserMoviesList(
                            userState.userId!, oldName, newName);
                      }

                      nameController.clear();
                    }
                  },
                ),
                const SizedBox(
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

    if (userState.userId != null && userState.userId!.isNotEmpty) {
      serviceAgent.removeUserMoviesList(userState.userId!, moviesList.name);
    }
  }

  Widget getBody() {
    final bottomPadding = Md3NavigationMetrics.bottomMargin(context) + 24;

    Widget widgetToReturn = moviesList.listMovies.isNotEmpty
        ? Container(
            color: Md3Colors.background,
            padding: const EdgeInsets.only(top: 8),
            child: MMoviesAnimatedList(
              buildItemFunction: buildItem,
              isPremium: false,
              listKey: MyGlobals.personalListsKey,
              movies: moviesList.listMovies,
              padding: EdgeInsets.only(bottom: bottomPadding),
            ),
          )
        : Md3Page(
            padding: EdgeInsets.fromLTRB(
              Md3Layout.pageHorizontalInset(context),
              18,
              Md3Layout.pageHorizontalInset(context),
              bottomPadding,
            ),
            child: Md3Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.playlist_add_rounded,
                    color: Md3Colors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This list is empty',
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use Search to add movies and TV shows to this list.',
                    style: TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Md3PrimaryButton(
                    text: 'Search Movies or TV Shows',
                    icon: Icons.search_rounded,
                    onPressed: () => Navigator.of(context).push(
                      RouteHelper.createRoute(
                        () => const SearchStandalonePage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    return widgetToReturn;
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey globalKey = GlobalKey();

    if (ModalRoute.of(context)!.isCurrent && moviesList.listMovies.isNotEmpty) {
      MyGlobals.activeKey = globalKey;
    }

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
            child: Text(
          moviesList.name,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
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
                          color: Theme.of(context).indicatorColor,
                        ),
                        title: const Text("Remove List"),
                      ))),
              const PopupMenuDivider(
                height: 5,
              ),
              PopupMenuItem<String>(
                  child: GestureDetector(
                      onTap: () => renameListButtonClicked(),
                      child: ListTile(
                        leading: Icon(
                          Icons.edit,
                          size: 25,
                          color: Theme.of(context).indicatorColor,
                        ),
                        title: const Text("Change List Name"),
                      ))),
            ],
          ),
      ],
    );

    return Scaffold(
        backgroundColor: Md3Colors.background,
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(AdManager.listBannerAd),
                ),
                elevation: 0.7,
                automaticallyImplyLeading: false)
            : PreferredSize(
                preferredSize: const Size(0, 0), child: Container()),
        body: Scaffold(
            backgroundColor: Md3Colors.background,
            appBar: AppBar(
              backgroundColor: Md3Colors.background,
              foregroundColor: Md3Colors.text,
              elevation: 0,
              title: headingField,
            ),
            body: Container(key: globalKey, child: getBody())));
  }
}
