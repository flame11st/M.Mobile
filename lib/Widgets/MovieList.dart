import 'package:app_review/app_review.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/web_symbols_icons.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/EmptyMoviesCard.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MovieList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MovieListState();
  }
}

class MovieListState extends State<MovieList>
    with SingleTickerProviderStateMixin {
  TabController tabController;

  // InterstitialAd _interstitialAd;

  @override
  void initState() {
    super.initState();
    tabController = new TabController(vsync: this, length: 2);

    tabController.addListener(changeCurrentTabIndex);

    _initAdMob();
  }

  changeCurrentTabIndex() {
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    moviesState.setCurrentTabIndex(tabController.index);
  }

  @override
  void dispose() {
    AdManager.hideBanner();
    tabController.dispose();

    super.dispose();
  }

  Future<void> _initAdMob() {
    // TODO: Initialize AdMob SDK
    return MobileAds.instance.initialize();
  }

  requestReview() async {
    final userState = Provider.of<UserState>(context, listen: false);
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
                              fontSize: 23,
                              color: Theme.of(context).accentColor),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Your reviews keep our small team motivated to make MovieDiary better.\n\n'
                          '5 stars rating makes us really happy',
                          style: TextStyle(fontSize: 17),
                          textAlign: TextAlign.center,
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
    return EmptyMoviesCard(tabName: tabName);
  }

  @override
  Widget build(BuildContext context) {
    if (tabController.animation.value != 1 &&
        tabController.animation.value != 0) {
      final targetIndex = tabController.animation.value.round();

      tabController.animateTo(targetIndex);
    }

    GlobalKey globalKey = new GlobalKey();

    if (ModalRoute.of(context).isCurrent) {
      MyGlobals.activeKey = globalKey;
    }

    final movieState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    if (userState.shouldRequestReview &&
        !userState.appReviewRequested &&
        movieState.userMovies.length > 6) {
      requestReview();
    }

    if (!userState.premiumPurchasedIncognito &&
        (userState.user == null || !userState.user.premiumPurchased) &&
        movieState.userMovies.length > 0) {

      if (ModalRoute.of(context).isCurrent) AdManager.showBanner();
    } else if (AdManager.bannerVisible) {
      AdManager.bannerVisible = false;

      AdManager.hideBanner();
    }

    final List<Movie> watchlistMovies = movieState.watchlistMovies;
    final List<Movie> viewedMovies = movieState.viewedMovies;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                Icon(
                  Icons.playlist_play,
                  size: 30,
                ),
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
                Icon(
                  WebSymbols.ok,
                  size: 17,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  '  Viewed',
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
          // padding: EdgeInsets.only(top: AdManager.bannerVisible ? 60 : 0),
          color: Theme.of(context).primaryColor,
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    if (movieState.userMovies.length > 0 &&
                        watchlistMovies.isNotEmpty)
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
                    if (movieState.userMovies.isNotEmpty &&
                        watchlistMovies.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Your Watchlist is empty.',
                          style: Theme.of(context).textTheme.headline2,
                        ),
                      ),
                    if (movieState.userMovies.length == 0)
                      getEmptyMoviesCardWidget("Watchlist"),
                    if (movieState.userMovies.length == 0)
                      getEmptyMoviesCardWidget("Viewed list"),
                    if (movieState.userMovies.length > 0 &&
                        viewedMovies.isNotEmpty)
                      Container(
                        child: AnimatedList(
                          padding: EdgeInsets.only(bottom: 90),
                          key: movieState.viewedListKey,
                          initialItemCount: viewedMovies.length,
                          itemBuilder: (context, index, animation) {
                            if (viewedMovies.length <= index) return null;

                            return movieState.buildItem(
                                viewedMovies[index], animation,
                                isPremium: userState.isPremium,
                                context: context);
                          },
                        ),
                      ),
                    if (movieState.userMovies.isNotEmpty &&
                        viewedMovies.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Your Viewed list is empty.',
                          style: Theme.of(context).textTheme.headline2,
                        ),
                      )
                  ],
                ),
              )
            ],
          )),
      key: globalKey,
    );
  }
}
