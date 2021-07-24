import 'package:app_review/app_review.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieListType.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Widgets/Providers/MoviesState.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/MIconButton.dart';
import 'package:provider/provider.dart';
import '../MoviesListsPage.dart';
import 'MButton.dart';
import 'MCard.dart';
import 'MDialog.dart';
import 'MSnackBar.dart';

class MAddToListButton extends StatelessWidget {
  final serviceAgent = new ServiceAgent();
  final Movie movie;
  final MoviesList moviesList;
  final bool fromMenu;
  final double offset;
  final bannerVisible = AdManager.bannerVisible;

  MAddToListButton({this.movie, this.moviesList, this.fromMenu = false, this.offset});

  Widget getMovieListWidget(
      MoviesList list, BuildContext context, BuildContext dialogContext) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    serviceAgent.state = userState;

    bool movieInList =
        list.listMovies.any((element) => element.id == this.movie.id);

    return GestureDetector(
        onTap: () async {
          if (movieInList) return;

          if (bannerVisible) AdManager.showBanner(offset);

          Navigator.of(dialogContext).pop();

          Navigator.of(context).pop();

          if (fromMenu) {
            Navigator.of(context).pop();
          }

          await new Future.delayed(const Duration(milliseconds: 300));

          MSnackBar.showSnackBar(
              '"${movie.title}" added to your list "${list.name}"', true);

          if (!userState.isIncognitoMode) {
            await serviceAgent.addMovieToList(
                userState.userId, movie.id, list.name);
          }

          moviesState.addMovieToPersonalList(list.name, this.movie);
        },
        child: MCard(
            color: movieInList
                ? Theme.of(context).cardColor.withOpacity(0.9)
                : Theme.of(context).cardColor,
            padding: 15,
            marginLR: 2,
            marginBottom: 15,
            marginTop: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(list.listMovies.length.toString() +
                        " item" +
                        (list.listMovies.length == 1 ? "" : "s"))
                  ],
                )),
                if (movieInList) Icon(Icons.check)
              ],
            )));
  }

  void showListsDialog(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    if (bannerVisible) AdManager.hideBanner();

    var userLists = moviesState.personalMoviesLists;

    userLists.sort((a, b) => a.order > b.order ? 1 : 0);

    showDialog<String>(
        context: context,
        builder: (BuildContext context1) => AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headline5,
              content: Container(
                height: userLists.isEmpty
                    ? 100
                    : (80 * userLists.length + 80).toDouble(),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userLists.isNotEmpty)
                      Text(
                        'Select your personal list',
                        style: Theme.of(context).textTheme.headline2,
                      ),
                    SizedBox(
                      height: 10,
                    ),
                    Expanded(
                        child: ListView(
                      children: [
                        if (userLists.isEmpty)
                          Text(
                            "You haven't created any personal list yet.\n\n"
                            "You can go to the 'Personal Lists' page and create a new one.",
                            style: TextStyle(fontSize: 16),
                          ),
                        if (userLists.isEmpty)
                          SizedBox(
                            height: 10,
                          ),
                        for (int i = 0; i < userLists.length; i++)
                          getMovieListWidget(userLists[i], context, context1),
                      ],
                    )),
                  ],
                ),
              ),
              actions: [
                MButton(
                  width: (MediaQuery.of(context).size.width / 2) - 55,
                  active: true,
                  text: 'Personal Lists',
                  onPressedCallback: () {
                    Navigator.of(context).pop();

                    Navigator.of(context1).pop();

                    if (bannerVisible) AdManager.showBanner(offset);

                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => MoviesListsPage(
                              initialPageIndex: 1,
                            )));
                  },
                ),
                SizedBox(
                  width: 10,
                ),
                MButton(
                  width: (MediaQuery.of(context).size.width / 2) - 55,
                  active: true,
                  text: "Close",
                  parentContext: context,
                  onPressedCallback: () {
                    if (bannerVisible) AdManager.showBanner(offset);

                    Navigator.of(context1).pop();
                  },
                ),
              ],
            ));
  }

  removeMovieFromList(BuildContext context) async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    if (!userState.isIncognitoMode) {
      await serviceAgent.removeMovieFromList(
          userState.userId, movie.id, moviesList.name);
    }

    Navigator.of(context).pop();

    if (fromMenu) {
      Navigator.of(context).pop();
    }

    await new Future.delayed(const Duration(milliseconds: 300));

    MSnackBar.showSnackBar(
        '"${movie.title}" removed from your list "${moviesList.name}"', true);

    moviesState.removeMovieFromPersonalList(moviesList.name, movie);
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);

    bool isRemove = moviesList != null;
    var text = isRemove ? 'Remove from this List' : 'Add to Personal List';

    if (serviceAgent.state == null) serviceAgent.state = userState;

    return MButton(
      prependIcon: isRemove ? Icons.clear : Icons.add,
      height: 40,
      active: true,
      width: MediaQuery.of(context).size.width - 100,
      text: text,
      onPressedCallback: () async {
        isRemove ? removeMovieFromList(context) : showListsDialog(context);
      },
    );
  }
}
