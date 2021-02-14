import 'package:app_review/app_review.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieListType.dart';
import 'package:mmobile/Enums/MovieRate.dart';
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

class MIconAddToListButton extends StatelessWidget {
  final icon;
  final serviceAgent = new ServiceAgent();
  final width;
  final color;
  final bool fromSearch;
  final String hint;
  final Movie movie;
  final int movieRate;
  final bool shouldRequestReview;

  MIconAddToListButton(
      {this.icon,
      this.width,
      this.color,
      this.fromSearch = false,
      this.shouldRequestReview = false,
      this.hint,
      this.movie,
      this.movieRate});

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

          Navigator.of(dialogContext).pop();

          Navigator.of(context).pop();

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movieInList)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Already added to list',
                        style: TextStyle(fontSize: 12),
                      ),
                      Icon(Icons.check)
                    ],
                  ),
                if (movieInList)
                  SizedBox(
                    height: 10,
                  ),
                Text(
                  list.name,
                  style: Theme.of(context).textTheme.headline5,
                ),
              ],
            )));
  }

  void showListsDialog(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    var userLists = moviesState.moviesLists
        .where((element) => element.movieListType == MovieListType.personal)
        .toList();
    userLists.sort((a, b) => a.order > b.order ? 1 : 0);

    showDialog<String>(
        context: context,
        builder: (BuildContext context1) => AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headline5,
              content: Container(
                // height: userLists.isEmpty ? 300 : MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
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
                            "You haven't created any personal list.\n\n"
                            "You can go to 'Personal Lists' page and create a new one.",
                            style: Theme.of(context).textTheme.headline2,
                          ),
                        if (userLists.isEmpty)
                          SizedBox(
                            height: 10,
                          ),
                        if (userLists.isEmpty)
                          MButton(
                            active: true,
                            text: 'Personal Lists',
                            onPressedCallback: () {
                              Navigator.of(context1).pop();

                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) => MoviesListsPage(
                                        initialPageIndex: 1,
                                      )));
                            },
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
                  active: true,
                  text: "Close",
                  parentContext: context,
                  onPressedCallback: () {
                    Navigator.of(context1).pop();
                  },
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return MIconButton(
      width: width,
      icon: icon,
      color: color,
      hint: hint,
      onPressedCallback: () async {
        showListsDialog(context);
      },
    );
  }
}
