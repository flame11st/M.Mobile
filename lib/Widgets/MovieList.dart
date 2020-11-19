import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/MoviesListsPage.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
import 'SearchDelegate.dart';

class MovieList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MovieListState();
  }
}

class MovieListState extends State<MovieList>
    with SingleTickerProviderStateMixin {
  TabController tabController;

  // List<Movie> watchlistMovies;
  // List<Movie> viewedMovies;
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
  void initState() {
    super.initState();
    tabController = new TabController(vsync: this, length: 2);

    tabController.addListener(changeCurrentTabIndex);
  }

  changeCurrentTabIndex() {
    final moviesState = Provider.of<MoviesState>(context);

    moviesState.setCurrentTabIndex(tabController.index);
  }

  @override
  void dispose() {
    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (tabController.animation.value != 1 &&
        tabController.animation.value != 0) {
      final targetIndex = tabController.previousIndex == 0 ? 1 : 0;

      tabController.animateTo(targetIndex);
    }

    final provider = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    final List<Movie> watchlistMovies = provider.watchlistMovies;
    final List<Movie> viewedMovies = provider.viewedMovies;
    MyGlobals.scaffoldKey = new GlobalKey();

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: TabBar(
          controller: tabController,
          indicatorColor: Theme.of(context).accentColor,
          labelColor: Theme.of(context).accentColor,
          unselectedLabelColor: Theme.of(context).hintColor,
          tabs: [
            Tab(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.queue_play_next),
                SizedBox(
                  width: 7,
                ),
                Text(
                  'Watchlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            )),
            Tab(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.check),
                SizedBox(
                  width: 5,
                ),
                Text(
                  'Viewed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            )),
          ],
        ),
      ),
      body: Container(
        color: Theme.of(context).primaryColor,
        child: TabBarView(
          controller: tabController,
          children: [
            if (provider.userMovies.length > 0)
              AnimatedList(
                padding: EdgeInsets.only(bottom: 90),
                key: provider.watchlistKey,
                initialItemCount: watchlistMovies.length,
                itemBuilder: (context, index, animation) {
                  if (watchlistMovies.length <= index) return null;

                  return provider.buildItem(watchlistMovies[index], animation);
                },
              ),
            if (provider.userMovies.length == 0)
              Column(children: [
                MCard(
                  marginLR: 20,
                  child: Column(
                    children: [
                      Text("You didn't add any Movie or TV Series yet. \n\n"
                          "Please use Search to add items to watch or already watched. \n\n"
                          "Also you can check Lists with popular Movies or TV Series, top rated, etc.\n\n",
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 16
                      ),),
                      MButton(
                        active: true,
                        text: 'Find Movie or TV Show',
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
                      MButton(
                        active: true,
                        text: 'Open Lists',
                        prependIcon: Icons.list,
                        width: MediaQuery.of(context).size.width - 50,
                        onPressedCallback: () => Navigator.of(context)
                            .push(_createRoute(() => MoviesListsPage())),
                      )
                    ],
                  ),
                )
              ]),
            if (provider.userMovies.length == 0)
              Column(children: [
                MCard(
                  marginLR: 20,
                  child: Column(
                    children: [
                      Text("You didn't add any Movie or TV Series yet. \n\n"
                          "Please use Search to add items to watch or already watched. \n\n"
                          "Also you can check Lists with popular Movies or TV Series, top rated, etc.\n\n",
                        style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 16
                        ),),
                      MButton(
                        active: true,
                        text: 'Find Movie or TV Show',
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
                      MButton(
                        active: true,
                        text: 'Open Lists',
                        prependIcon: Icons.list,
                        width: MediaQuery.of(context).size.width - 50,
                        onPressedCallback: () => Navigator.of(context)
                            .push(_createRoute(() => MoviesListsPage())),
                      )
                    ],
                  ),
                )
              ]),
            if (provider.userMovies.length > 0)
            Container(
              child: AnimatedList(
                padding: EdgeInsets.only(bottom: 90),
                key: provider.viewedListKey,
                initialItemCount: viewedMovies.length,
                itemBuilder: (context, index, animation) {
                  if (viewedMovies.length <= index) return null;

                  return provider.buildItem(viewedMovies[index], animation,
                      isPremium: userState.isPremium, context: context);
                },
              ),
            )
          ],
        ),
      ),
      key: MyGlobals.scaffoldKey,
    );
  }
}
