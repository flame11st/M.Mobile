import 'package:app_review/app_review.dart';
import 'package:flutter/cupertino.dart';
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

  requestReview() async {
    final userState = Provider.of<UserState>(context);
    userState.shouldRequestReview = false;

    await userState.setAppReviewRequested(true);
    await new Future.delayed(const Duration(milliseconds: 2000));

    showDialog<String>(
        context: context,
        builder: (BuildContext context1) => AlertDialog(
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headline5,
              content: Container(
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Enjoying MovieDiary?',
                          style: TextStyle(
                              fontSize: 23, color: Theme.of(context).accentColor),
                        ),
                        SizedBox(height: 10,),
                        Text(
                          'Your reviews keep our small team motivated to make MovieDiary better.\n\n'
                              '5 star rating makes us really happy',
                          style: TextStyle(fontSize: 17),textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Image(
                      image: AssetImage("Assets/5-star-image.png"),
                      width: MediaQuery.of(context).size.width,
                      height: 200,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MButton(
                          width: (MediaQuery.of(context).size.width - 150) / 2,
                          active: true,
                          text: 'Rate MovieDiary',
                          parentContext: context,
                          onPressedCallback: () {
                            Navigator.of(context1).pop();

                            AppReview.requestReview.then((onValue) {});
                          },
                        ),
                        MButton(
                          width: (MediaQuery.of(context).size.width - 150) / 2,
                          active: true,
                          text: 'Maybe later',
                          parentContext: context,
                          onPressedCallback: () => Navigator.of(context1).pop(),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ));
  }

  getEmptyMoviesCardWidget(String tabName) {
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
              "You didn't add any Movie or TV Series yet. \n\n"
              "Please use Search to add items to your $tabName. \n\n"
              "Also you can check Lists with popular Movies or TV Series, top rated, etc.\n\n",
              style:
                  TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
            ),
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

  @override
  Widget build(BuildContext context) {
    if (tabController.animation.value != 1 &&
        tabController.animation.value != 0) {
      final targetIndex = tabController.animation.value.round();

      tabController.animateTo(targetIndex);
    }

    final movieState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    if (userState.shouldRequestReview &&
        !userState.appReviewRequested &&
        movieState.userMovies.length > 10) {
      requestReview();
    }

    final List<Movie> watchlistMovies = movieState.watchlistMovies;
    final List<Movie> viewedMovies = movieState.viewedMovies;
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
            if (movieState.userMovies.length > 0)
              AnimatedList(
                padding: EdgeInsets.only(bottom: 90),
                key: movieState.watchlistKey,
                initialItemCount: watchlistMovies.length,
                itemBuilder: (context, index, animation) {
                  if (watchlistMovies.length <= index) return null;

                  return movieState.buildItem(
                      watchlistMovies[index], animation);
                },
              ),
            if (movieState.userMovies.length == 0)
              getEmptyMoviesCardWidget("Watchlist"),
            if (movieState.userMovies.length == 0)
              getEmptyMoviesCardWidget("Viewed list"),
            if (movieState.userMovies.length > 0)
              Container(
                child: AnimatedList(
                  padding: EdgeInsets.only(bottom: 90),
                  key: movieState.viewedListKey,
                  initialItemCount: viewedMovies.length,
                  itemBuilder: (context, index, animation) {
                    if (viewedMovies.length <= index) return null;

                    return movieState.buildItem(viewedMovies[index], animation,
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
