import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';

import '../Helpers/RouteHelper.dart';
import 'MoviesListsPage.dart';
import 'RecommendationsPage.dart';
import 'SearchDelegate.dart';
import 'Shared/MButton.dart';
import 'Shared/MCard.dart';

class EmptyMoviesCard extends StatelessWidget {
  final String tabName;

  const EmptyMoviesCard({super.key, required this.tabName});

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
    return SingleChildScrollView(child: MCard(
      marginLR: 20,
      child: Column(
        children: [
          Text(
            "Welcome to MovieDiary!",
            style: TextStyle(
                color: Theme.of(context).indicatorColor,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 15,
          ),
          Text(
            "This powerful app lets you keep track on movies you want to watch and movies you've already seen.",
            style:
            TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            "With our AI recommendation engine"
                " you can get personalized movie suggestions tailored to your taste, making your movie-watching experience even more enjoyable!",
            style:
            TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
          ),
          SizedBox(
            height: 15,
          ),
          MButton(
            height: 40,
            width: MediaQuery.of(context).size.width - 40,
            backgroundColor: Theme.of(context).indicatorColor,
            borderRadius: 20,
            prependIcon: Icons.electric_bolt,
            prependIconColor: Theme.of(context).cardColor,
            text: "Get Recommendations",
            onPressedCallback: () {
              Navigator.of(context)
                  .push(RouteHelper.createRoute(() => RecommendationsPage()));
            },
            active: true,
            textColor: Theme.of(context).cardColor,
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
          MButton(height: 40,
            borderRadius: 30,
            active: true,
            text: 'Open Lists',
            prependIcon: Entypo.menu,
            width: MediaQuery.of(context).size.width - 40,
            onPressedCallback: () => Navigator.of(context)
                .push(_createRoute(() => MoviesListsPage(initialPageIndex: 0,))),
          ),
        ],
      ),
    ));
  }
}
