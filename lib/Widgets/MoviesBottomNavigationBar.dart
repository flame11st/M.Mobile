import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:mmobile/Widgets/MoviesListsPage.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:provider/provider.dart';

import 'MoviesFilter.dart';
import 'Premium.dart';
import 'Providers/MoviesState.dart';
import 'Settings.dart';
import 'Shared/MBoxShadow.dart';
import 'Shared/MIconButton.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  Route _createRoute(Function page) {
    if (Platform.isIOS) return MaterialPageRoute(builder: (context) => page());
    
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    var additionalPadding = Platform.isIOS ? 20 : 0;
    var middleSizedBoxWidth = 50.0;
    var buttonWidth = (MediaQuery.of(context).size.width - middleSizedBoxWidth) / 4;

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
                  ? Theme.of(context).accentColor.withOpacity(0.9)
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
              hint: 'Settings',
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).hintColor,
              ),
              onPressedCallback: () {
                Navigator.of(context)
                    .push(_createRoute(() => Settings()));
              },
            ),
            SizedBox(width: middleSizedBoxWidth,),
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
                    .push(_createRoute(() => MoviesListsPage()));
              },
            ),
            MIconButton(
              width: buttonWidth,
              withBorder: false,
              hint: 'Premium',
              icon: Icon(
                userState.isPremium
                    ? Icons.check
                    : Icons.monetization_on,
                color: Colors.green,
              ),
              onPressedCallback: () {
                Navigator.of(context)
                    .push(_createRoute(() => Premium()));
              },
            ),
          ],
        ));
  }
}
