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
import 'Shared/m_dialog.dart';
import 'Shared/m_movies_animated_list.dart';

class MoviesListPage extends StatefulWidget {
  final MoviesList moviesList;
  final String? backTooltip;

  const MoviesListPage({
    super.key,
    required this.moviesList,
    this.backTooltip,
  });

  @override
  State<StatefulWidget> createState() {
    return MovieListPageState(moviesList);
  }
}

class MovieListPageState extends State<MoviesListPage> {
  late MoviesList moviesList;

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

  Future<void> removeListButtonClicked() async {
    final userState = Provider.of<UserState>(context, listen: false);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final listName = moviesList.name;

    final confirmed = await showMd3ConfirmationDialog(
      context: context,
      title: 'Remove “$listName”?',
      body: 'The list will be deleted. Movies you watched will stay in Viewed.',
      confirmLabel: 'Remove list',
      failureMessage:
          'Couldn’t remove this list. Check your connection and try again.',
      onConfirm: () async {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty) {
          return;
        }

        final response =
            await serviceAgent.removeUserMoviesList(userId, listName);
        if (response.statusCode != 200) {
          throw StateError('Remove list request failed.');
        }
      },
    );

    if (!confirmed || !mounted) {
      return;
    }

    moviesState.removeMoviesList(listName);
    MSnackBar.showSnackBar('“$listName” removed.', true);
    Navigator.of(context).pop();
  }

  Future<void> renameListButtonClicked() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final oldName = moviesList.name;

    final newName = await showMd3TextInputDialog(
      context: context,
      title: 'Rename list',
      body: 'Choose a clear name you’ll recognize in Personal lists.',
      fieldLabel: 'List name',
      initialValue: oldName,
      confirmLabel: 'Save name',
      validator: (value) {
        if (value.isEmpty) {
          return 'Enter a list name.';
        }

        final normalizedValue = value.toLowerCase();
        final duplicate = moviesState.personalMoviesLists.any(
          (list) =>
              !identical(list, moviesList) &&
              list.name.trim().toLowerCase() == normalizedValue,
        );
        return duplicate ? 'A list with this name already exists.' : null;
      },
      failureMessage:
          'Couldn’t rename this list. Check your connection and try again.',
      onConfirm: (value) async {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty) {
          return;
        }

        final response =
            await serviceAgent.renameUserMoviesList(userId, oldName, value);
        if (response.statusCode != 200) {
          throw StateError('Rename list request failed.');
        }
      },
    );

    if (newName == null || !mounted || newName == oldName) {
      return;
    }

    moviesState.renameMoviesList(oldName, newName);
    setState(() {});
    MSnackBar.showSnackBar('Renamed to “$newName”.', true);
  }

  Future<void> _openSearch() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    await Navigator.of(context).push(
      RouteHelper.createRoute(
        () => SearchStandalonePage(
          originatingPersonalList: moviesList,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    final listStillExists = moviesState.personalMoviesLists.any(
      (list) => identical(list, moviesList),
    );
    if (!listStillExists) {
      final removedListName = moviesList.name;
      Navigator.of(context).pop();
      MSnackBar.showSnackBar(
        '“$removedListName” is no longer available.',
        false,
      );
      return;
    }

    setState(() {});
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
                    onPressed: _openSearch,
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
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'remove') {
                removeListButtonClicked();
              } else if (value == 'rename') {
                renameListButtonClicked();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'remove',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    size: 24,
                    color: Md3Colors.danger,
                  ),
                  title: Text('Remove list'),
                ),
              ),
              const PopupMenuDivider(
                height: 5,
              ),
              const PopupMenuItem<String>(
                value: 'rename',
                child: ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    size: 24,
                    color: Md3Colors.primary,
                  ),
                  title: Text('Rename list'),
                ),
              ),
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
              automaticallyImplyLeading: widget.backTooltip == null,
              leading: widget.backTooltip == null
                  ? null
                  : IconButton(
                      tooltip: widget.backTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
              title: headingField,
            ),
            body: Container(key: globalKey, child: getBody())));
  }
}
