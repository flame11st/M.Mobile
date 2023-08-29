import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:mmobile/Widgets/MoviesListsPage.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/RecommendationsPage.dart';
import 'package:provider/provider.dart';

import 'MoviesFilter.dart';
import 'Providers/MoviesState.dart';
import 'SearchDelegate.dart';
import 'Settings.dart';
import 'Shared/MIconButton.dart';
import 'package:mmobile/Helpers/RouteHelper.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
   @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    var additionalPadding = Platform.isIOS ? 20 : 0;
    var middleButtonWidth = 90.0;
    var buttonWidth = (MediaQuery.of(context).size.width - middleButtonWidth) / 4;

    return Container(
      padding: EdgeInsets.only(bottom: 0.0 + additionalPadding),
        height: 60.0 + additionalPadding,
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 0.9,
            ),
          ],
          color: Theme.of(context).primaryColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            MIconButton(
              width: buttonWidth,
              withBorder: false,
              hint: 'Filters',
              icon: Icon(
                Icons.movie_filter,
                color: moviesState.isAnyFilterSelected()
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).hintColor,
              ),
              color: moviesState.isAnyFilterSelected()
                  ? Theme.of(context).indicatorColor.withOpacity(0.9)
                  : Theme.of(context).primaryColor,
              fontColor: moviesState.isAnyFilterSelected()
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).hintColor,
              onPressedCallback: () async {
                showModalBottomSheet<void>(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (BuildContext context) => MoviesFilter());
              },
            ),
            MIconButton(
              width: buttonWidth,
              withBorder: false,
              hint: 'Search',
              icon: Icon(
                Icons.search,
                color: Theme.of(context).hintColor,
              ),
              onPressedCallback: () {
                showSearch(
                  context: context,
                  delegate: MSearchDelegate(),
                );
              },
            ),
            MIconButton(
              width: middleButtonWidth,
              withBorder: false,
              hint: 'Discover',
              icon: Icon(
                Icons.movie_creation_outlined,
                color: Theme.of(context).hintColor,
              ),
              onPressedCallback: () {
                Navigator.of(context)
                    .push(RouteHelper.createRoute(() => RecommendationsPage()));
              },
            ),
            MIconButton(
              width: buttonWidth,
              withBorder: false,
              hint: 'Lists',
              icon: Icon(
                Entypo.menu,
                color: Theme.of(context).hintColor,
              ),
              onPressedCallback: () {
                Navigator.of(context)
                    .push(RouteHelper.createRoute(() => MoviesListsPage(initialPageIndex: 0,)));
              },
            ),
            MIconButton(
              width: buttonWidth,
              withBorder: false,
              hint: 'Settings',
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).hintColor,
              ),
              onPressedCallback: () {
                Navigator.of(context)
                    .push(RouteHelper.createRoute(() => Settings()));
              },
            ),
          ],
        ));
  }
}
