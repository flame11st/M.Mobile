import 'package:flutter/material.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/MoviesListPage.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:mmobile/Widgets/Shared/MIconButton.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';

class MoviesListsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MoviesListsPageState();
  }
}

class MoviesListsPageState extends State<MoviesListsPage>
    with SingleTickerProviderStateMixin {
  Route _createRoute(MoviesList moviesList) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => MoviesListPage(moviesList: moviesList),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1.0, 0.0);
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

  getMovieListWidget(int order) {
    final moviesState = Provider.of<MoviesState>(context);
    final moviesList = moviesState.moviesLists
        .singleWhere((element) => element.order == order);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(_createRoute(moviesList)),
      child: MCard(
          child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(moviesList.name, style: Theme.of(context).textTheme.headline5,),
                  Icon(Icons.arrow_forward, color: Theme.of(context).hintColor,),
                ],
              ))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.format_list_bulleted,
              size: 25,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Movies Lists',
              style: Theme.of(context).textTheme.headline5,
            )
          ],
        ),
      ],
    );

    // MyGlobals.scaffoldKey = new GlobalKey();

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          title: headingField,
        ),
        body: SingleChildScrollView(child: Container(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
            color: Theme.of(context).primaryColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (moviesState.moviesLists.length == 0)
                  SizedBox(height: 40,),
                if (moviesState.moviesLists.length == 0)
                  Center(child: CircularProgressIndicator()),
                if (moviesState.moviesLists.length > 0)
                for (int i = 0; i < moviesState.moviesLists.length; i++)
                  getMovieListWidget(i),
              ],
            )))
    );
  }
}
