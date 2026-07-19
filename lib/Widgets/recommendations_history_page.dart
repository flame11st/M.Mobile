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
import 'Shared/md3_ui.dart';
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

    const headingField = Text("Recommendations History");

    final moviesListWidget = Container(
        key: globalKey,
        color: Md3Colors.background,
        padding: const EdgeInsets.only(top: 8),
        child: MMoviesAnimatedList(
          buildItemFunction: buildItem,
          isPremium: userState!.isPremium,
          movies: history,
          padding: const EdgeInsets.only(bottom: 16),
        ));

    const emptyHistoryWidget = Md3Page(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Md3Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No recommendation history yet',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start Discovery from Discover to save recommendation batches here.',
              style: TextStyle(
                color: Md3Colors.muted,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    const loaderWidget = Center(child: CircularProgressIndicator());

    MyGlobals.personalListsKey = GlobalKey<AnimatedListState>();

    return Scaffold(
        backgroundColor: Md3Colors.background,
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(
                      AdManager.recommendationsHistoryBannerAd),
                ),
                elevation: 0.7,
                automaticallyImplyLeading: false)
            : PreferredSize(
                preferredSize: const Size(0, 0), child: Container()),
        body: Scaffold(
            backgroundColor: Md3Colors.background,
            appBar: AppBar(
              title: headingField,
              backgroundColor: Md3Colors.background,
              foregroundColor: Md3Colors.text,
              elevation: 0,
            ),
            body: isLoading
                ? loaderWidget
                : history.isEmpty
                    ? emptyHistoryWidget
                    : moviesListWidget));
  }
}
