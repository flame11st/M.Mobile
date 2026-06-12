import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:provider/provider.dart';
import '../Helpers/rating_helper.dart';
import 'movie_list_item.dart';
import 'Providers/movies_state.dart';
import 'Shared/m_movies_animated_list.dart';

class RecommendationsHistoryPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RecommendationsHistoryPageState();
  }
}

class RecommendationsHistoryPageState
    extends State<RecommendationsHistoryPage> {
  final serviceAgent = ServiceAgent();
  GlobalKey? globalKey;
  UserState? userState;
  MoviesState? movieState;
  List<Movie> history = <Movie>[];
  bool requested = false;
  bool isLoading = false;

  getHistory() async {
    setState(() {
      isLoading = true;
    });

    userState ??= Provider.of<UserState>(context, listen: false);

    var moviesResponse =
        await serviceAgent.getUserRecommendationsHistory(userState!.userId!);

    if (moviesResponse.statusCode == 200) {
      Iterable iterableMovies = json.decode(moviesResponse.body);

      if (iterableMovies.isNotEmpty) {
        List<Movie> movies = iterableMovies.map((model) {
          return Movie.fromJson(model);
        }).toList();

        setState(() {
          RatingHelper.refreshMoviesRating(movies, context);

          history = movies;
        });
      }
    }

    setState(() {
      requested = true;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userState == null) {
      userState = Provider.of<UserState>(context, listen: false);
      movieState = Provider.of<MoviesState>(context, listen: false);
    }

    if (userState!.user != null && history.isEmpty && !requested) {
      getHistory();
    }

    if (ModalRoute.of(context)!.isCurrent &&
        (globalKey == null || globalKey != MyGlobals.activeKey)) {
      globalKey = GlobalKey();

      MyGlobals.activeKey = globalKey;
    }

    Widget buildItem(Movie movie, Animation<double> animation,
        {bool isPremium = false, required BuildContext context}) {
      return SizeTransition(
          key: ObjectKey(movie),
          sizeFactor: animation,
          child: Column(
            children: [MovieListItem(movie: movie)],
          ));
    }

    final headingField = Text(
      "Recommendations History",
      style: Theme.of(context).textTheme.displayMedium,
    );

    final moviesListWidget = Container(
        key: globalKey,
        color: Theme.of(context).primaryColor,
        child: MMoviesAnimatedList(
          buildItemFunction: buildItem,
          isPremium: userState!.isPremium,
          movies: history,
        ));

    final emptyHistoryWidget = Container(
      padding: const EdgeInsets.all(20),
      child: Text(
        "Recommendations History is empty",
        style: Theme.of(context).textTheme.displayMedium,
      ),
    );

    final loaderWidget =
        Container(child: const Center(child: CircularProgressIndicator()));

    MyGlobals.personalListsKey = GlobalKey<AnimatedListState>();

    return Scaffold(
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(
                      AdManager.recommendationsHistoryBannerAd!),
                ),
                elevation: 0.7,
                automaticallyImplyLeading: false)
            : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
        body: Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            appBar: AppBar(title: headingField),
            body: isLoading
                ? loaderWidget
                : history.isEmpty
                    ? emptyHistoryWidget
                    : moviesListWidget));
  }
}

