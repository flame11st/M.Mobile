import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:provider/provider.dart';
import '../Enums/MovieRate.dart';
import '../Enums/MovieType.dart';
import '../Helpers/RatingHelper.dart';
import '../Helpers/RouteHelper.dart';
import 'MovieListItem.dart';
import 'Providers/MoviesState.dart';
import 'RecommendationsHistoryPage.dart';
import 'Shared/FilterButton.dart';
import 'Shared/MButton.dart';
import 'Shared/MCard.dart';
import 'Shared/MIconButton.dart';
import 'Shared/MMoviesAnimatedList.dart';

class RecommendationsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RecommendationsPageState();
  }
}

class RecommendationsPageState extends State<RecommendationsPage> {
  final serviceAgent = new ServiceAgent();
  GlobalKey? globalKey;
  UserState? userState;
  MoviesState? movieState;
  List<Movie> recommendedMovies = <Movie>[];
  bool isLoading = false;
  bool isButtonDisabled = false;
  var selectedType = MovieType.movie;

  setSelectedType(MovieType type) {
    setState(() {
      selectedType = type;
    });
  }

  getRecommendations() async {
    setState(() {
      isLoading = true;
      isButtonDisabled = true;
    });

    if (userState == null) {
      userState = Provider.of<UserState>(context, listen: false);
      movieState = Provider.of<MoviesState>(context, listen: false);
    }

    if (!userState!.isPremium && userState!.aiRequestsCount % 3 == 0) {
      AdManager.showInterstitialAd();
    }

    var moviesResponse;
    if (userState!.isIncognitoMode) {
      final moviesIds = movieState!.userMovies
          .where((m) => m.movieRate == MovieRate.liked)
          .map((e) => e.title)
          .toList();

      var encodedTitles = json.encode(moviesIds);

      moviesResponse = await serviceAgent.getMovieRecommendationsByTitles(
          encodedTitles, selectedType);
    } else {
      moviesResponse = await serviceAgent.getUserRecommendations(
          userState!.userId!, selectedType);
    }

    if (moviesResponse.statusCode != 200) {
      setState(() {
        isLoading = false;
        isButtonDisabled = false;
      });
    }

    Iterable iterableMovies = json.decode(moviesResponse.body);

    if (iterableMovies.length != 0) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      setState(() {
        recommendedMovies = movies;
        isLoading = false;
        isButtonDisabled = false;
      });

      userState!.increaseAiRequestsCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    var movieState1 = Provider.of<MoviesState>(context, listen: false);

    if (userState == null) {
      userState = Provider.of<UserState>(context, listen: false);
      movieState = Provider.of<MoviesState>(context, listen: false);
    }

    if (recommendedMovies.isNotEmpty) {
      RatingHelper.refreshMoviesRating(recommendedMovies, context);
    }

    if (serviceAgent.state == null) {
      serviceAgent.state = userState;
    }

    if (ModalRoute.of(context)!.isCurrent &&
        (this.globalKey == null || this.globalKey != MyGlobals.activeKey)) {
      globalKey = new GlobalKey();

      MyGlobals.activeKey = globalKey;
    }

    Widget buildItem(Movie movie, Animation<double> animation,
        {bool isPremium = false, required BuildContext context}) {
      return SizeTransition(
          key: ObjectKey(movie),
          sizeFactor: animation,
          child: Column(
            children: [MovieListItem(movie: movie, showShortDescription: true,)],
          ));
    }

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
            child: Text(
          "Recommendations",
          style: Theme.of(context).textTheme.headline2,
        )),
        if (userState!.user != null)
          IconButton(
              onPressed: () => {
                    Navigator.of(context).push(RouteHelper.createRoute(
                        () => RecommendationsHistoryPage()))
                  },
              icon: Icon(
                Icons.history,
                color: Theme.of(context).indicatorColor,
              ))
      ],
    );

    MyGlobals.personalListsKey = GlobalKey<AnimatedListState>();

    return Scaffold(
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(
                      AdManager.recommendationsBannerAd!),
                ),
                elevation: 0.7,
                automaticallyImplyLeading: false)
            : PreferredSize(preferredSize: Size(0, 0), child: Container()),
        body: Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            appBar: AppBar(title: headingField),
            body: Stack(children: [
              SizedBox(
                  height: 8,
                  child: isLoading
                      ? LinearProgressIndicator(
                          minHeight: 8,
                        )
                      : Text('')),
              Container(
                  margin: EdgeInsets.only(top: 8), // for linear progress
                  color: Theme.of(context).primaryColor,
                  child: ListView(shrinkWrap: true, children: <Widget>[
                    if (recommendedMovies.isEmpty)
                      MCard(
                          marginTop: 15,
                          marginLR: 10,
                          child: Column(children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                    color: Theme.of(context).indicatorColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                                children: <TextSpan>[
                                  new TextSpan(
                                      text:
                                          "Welcome to our movie recommendation system, powered by AI from the creators of ChatGPT!"),
                                  if (movieState!.userMovies.length < 10)
                                    new TextSpan(
                                        text:
                                            "\n\nTo make your recommendations more tailored to your tastes, we recommend you to rate at least 10 Movies or TV Shows.",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5),
                                  new TextSpan(
                                      text:
                                          "\n\nDiscover new movies personalized just for you."
                                          "\nBy analyzing your movie preferences and utilizing state-of-the-art machine learning algorithms, we can provide you with highly personalized movie recommendations that will blow your mind. "
                                          "\n\nGet ready to explore a world of cinematic wonders with just one click",
                                      style:
                                          Theme.of(context).textTheme.headline5)
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            MButton(
                              height: 50,
                              width: MediaQuery.of(context).size.width - 10,
                              prependIcon: Icons.history_outlined,
                              borderRadius: 25,
                              text: "Recommendations History",
                              onPressedCallback: () {
                                Navigator.of(context).push(
                                    RouteHelper.createRoute(
                                        () => RecommendationsHistoryPage()));
                              },
                              active: true,
                            ),
                          ])),
                  ])),
              if (recommendedMovies.isNotEmpty)
                Container(
                    key: globalKey,
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.only(bottom: 70),
                    color: Theme.of(context).primaryColor,
                    child: MMoviesAnimatedList(
                      buildItemFunction: buildItem,
                      isPremium: userState!.isPremium,
                      movies: recommendedMovies,
                    )),
              Align(
                  alignment: Alignment(0.0, 1),
                  child: Container(
                      margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                      height: 145,
                      child: MCard(
                          padding: 15,
                          child: Column(children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Text("Type:",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5),
                                  Row(children: [
                                    FilterIcon(
                                      height: 30,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(25),
                                          bottomLeft: Radius.circular(25)),
                                      width: MediaQuery.of(context).size.width /
                                              2 -
                                          60,
                                      icon: FontAwesome.video,
                                      text: 'Movies',
                                      isActive: selectedType == MovieType.movie,
                                      onPressedCallback: () {
                                        setSelectedType(MovieType.movie);
                                      },
                                    ),
                                    FilterIcon(
                                      height: 30,
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(25),
                                          bottomRight: Radius.circular(25)),
                                      width: MediaQuery.of(context).size.width /
                                              2 -
                                          60,
                                      icon: Icons.tv,
                                      text: 'TV Shows',
                                      isActive: selectedType == MovieType.tv,
                                      onPressedCallback: () {
                                        setSelectedType(MovieType.tv);
                                      },
                                    ),
                                  ]),
                                ]),
                            SizedBox(
                              height: 15,
                            ),
                            MButton(
                              height: 50,
                              width: MediaQuery.of(context).size.width - 10,
                              backgroundColor: Theme.of(context).indicatorColor,
                              prependIcon: Icons.bolt_sharp,
                              borderRadius: 25,
                              text: "Get Recommended "
                                  "${selectedType == MovieType.movie ? "Movies" : "TV Shows"}",
                              onPressedCallback: () => getRecommendations(),
                              active: !isButtonDisabled,
                              textColor: Theme.of(context).cardColor,
                            ),
                          ])))),
            ])));
  }
}
