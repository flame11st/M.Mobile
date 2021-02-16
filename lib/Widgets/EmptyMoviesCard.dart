import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';

import 'MoviesListsPage.dart';
import 'SearchDelegate.dart';
import 'Shared/MButton.dart';
import 'Shared/MCard.dart';

class EmptyMoviesCard extends StatelessWidget {
  final String tabName;

  const EmptyMoviesCard({Key key, this.tabName}) : super(key: key);

  Route _createRoute(Function page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      MCard(
        marginLR: 20,
        child: Column(
          children: [
            Text(
              "Welcome to MovieDiary!",
              style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "You haven't added any Movie or TV Series yet. \n\n"
                  "Please use Search to find and add items to your $tabName.",
              style:
              TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
            ),
            SizedBox(height: 10,),
            MButton(
              active: true,
              text: 'Find Movie or TV Series',
              prependIcon: Icons.search,
              width: MediaQuery.of(context).size.width - 50,
              onPressedCallback: () => showSearch(
                context: context,
                delegate: MSearchDelegate(),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "Check Lists with popular Movies or TV Series, top rated, etc.",
              style:
              TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
            ),
            SizedBox(
              height: 10,
            ),
            MButton(
              active: true,
              text: 'Open Lists',
              prependIcon: Entypo.menu,
              width: MediaQuery.of(context).size.width - 50,
              onPressedCallback: () => Navigator.of(context)
                  .push(_createRoute(() => MoviesListsPage())),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "You can create your personal Movies Lists and fill them in any way you want",
              style:
              TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
            ),
            SizedBox(
              height: 10,
            ),
            MButton(
              active: true,
              text: 'Open Personal Lists',
              prependIcon: Icons.person,
              width: MediaQuery.of(context).size.width - 50,
              onPressedCallback: () => Navigator.of(context)
                  .push(_createRoute(() => MoviesListsPage(initialPageIndex: 1,))),
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              "P.S. With this app you can't watch tv shows or movies!",
              style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
      )
    ]);
  }

}