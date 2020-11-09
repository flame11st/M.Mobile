import 'package:flutter/material.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:provider/provider.dart';

import 'MoviesFilter.dart';
import 'Premium.dart';
import 'Providers/MoviesState.dart';
import 'Settings.dart';
import 'Shared/MBoxShadow.dart';
import 'Shared/MIconButton.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    return Container(
        height: 58,
        width: double.infinity,
//            margin: EdgeInsets.all(5),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 3,
            ),
          ],
          color: Theme.of(context).primaryColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            MIconButton(
              icon: Icon(
                Icons.movie_filter,
                color: moviesState.isAnyFilterSelected()
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).hintColor,
              ),
              color: moviesState.isAnyFilterSelected()
                  ? Theme.of(context).accentColor
                  : Theme.of(context).primaryColor,
              onPressedCallback: () async {
                showModalBottomSheet<void>(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (BuildContext context) => MoviesFilter());
              },
            ),
            Hero(
              tag: 'settings',
              child: MIconButton(
                icon: Icon(
                  Icons.settings,
                  color: Theme.of(context).hintColor,
                ),
                onPressedCallback: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (ctx) => Settings()));
                },
              ),
            ),
            SizedBox(
              width: 80,
            ),
            GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (ctx) => Premium()));
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.9),
                        offset: Offset(0.0, 1.0),
                        blurRadius: 2,
                      ),
                    ],
                    color: Theme.of(context).primaryColor,
//                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.only(right: 10),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          userState.isPremium
                              ? Icons.check
                              : Icons.monetization_on,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Premium',
                        style: Theme.of(context).textTheme.headline5,
                      )
                    ],
                  ),
                ))
          ],
        ));
//
  }
}
