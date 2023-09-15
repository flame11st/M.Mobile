import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:provider/provider.dart';
import '../Helpers/RatingHelper.dart';
import '../Helpers/ad_manager.dart';
import 'MovieListItem.dart';
import 'Providers/MoviesState.dart';

class MSearchDelegate extends SearchDelegate {
  List<Movie> foundMovies = [];
  final serviceAgent = new ServiceAgent();
  UserState? userState;
  String? oldQuery;
  String? currentQuery;
  bool isLoading = false;

  int? searchTimestamp;
  bool notFound = false;
  bool showAdvancedCard = false;
  bool isAdvanced = false;
  GlobalKey? globalKey;

  getResultsWidget(String query, bool isResultSearch) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      if (query == '') {
        oldQuery = '';
        isLoading = false;
        setState(() => notFound = false);
        setState(() => foundMovies.clear());
      } else if (query != oldQuery || isLoading) {
        oldQuery = query;
        searchMovies(context, setState);
      }

      if (ModalRoute.of(context)!.isCurrent &&
          (this.globalKey == null || this.globalKey != MyGlobals.activeKey)) {
        globalKey = new GlobalKey();

        MyGlobals.activeKey = globalKey;
      }

      return Scaffold(
          appBar: AdManager.bannerVisible && AdManager.bannersReady
              ? AppBar(
                  title: Center(
                    child:
                        AdManager.getBannerWidget(isResultSearch ? AdManager.searchBanner2Ad! : AdManager.searchBannerAd!),
                  ),
                  automaticallyImplyLeading: false,
                  elevation: 0.7,
                )
              : PreferredSize(preferredSize: Size(0, 0), child: Container()),
          body: Container(
              key: globalKey,
              color: Theme.of(context).primaryColor,
              child: ListView(
                children: <Widget>[
                  SizedBox(
                      height: 5,
                      child: isLoading ? LinearProgressIndicator() : Text('')),
                  if (foundMovies.isEmpty && !notFound)
                    MCard(
                        marginTop: 15,
                        marginLR: 10,
                        child: Container(
                          child: Text(
                            "You can search in English and German languages.",
                            style: Theme.of(context).textTheme.headline5,
                          ),
                        )),
                  if (foundMovies.isEmpty && notFound)
                    MCard(
                        marginTop: 15,
                        marginLR: 10,
                        child: Container(
                          child: Text(
                            "Nothing found by the query. Try to find something else.",
                            style: Theme.of(context).textTheme.headline5,
                          ),
                        )),
                  for (final movie in foundMovies) MovieListItem(movie: movie),
                ],
              )));
    });
  }

  searchMovies(BuildContext context, StateSetter setStateFunction) async {
    currentQuery = query;
    setStateFunction(() => isLoading = true);

    if (userState == null) {
      userState = Provider.of<UserState>(context);
    }

    // Debounce
    final queryToDebounce = query;
    await Future.delayed(Duration(milliseconds: 2000));
    if (queryToDebounce != query) return;

    if (!userState!.isPremium && userState!.aiRequestsCount % 6 == 0 && ServiceAgent.showLoadingAd) {
      AdManager.showInterstitialAd();
    }

    var timestamp = DateTime.now().millisecondsSinceEpoch;

    var moviesResponse;

    final encoded = Uri.encodeFull(queryToDebounce).replaceAll('&', '%26');

    if (isAdvanced) {
      moviesResponse = await serviceAgent.advancedSearch(encoded);
    } else {
      moviesResponse = await serviceAgent.search(encoded);
    }

    if (searchTimestamp != null && timestamp < searchTimestamp!) return;

    if (moviesResponse.statusCode == 200) {
      searchTimestamp = timestamp;

      Iterable iterableMovies = json.decode(moviesResponse.body);
      final foundMoviesNew = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      RatingHelper.refreshMoviesRating(foundMoviesNew, context);

      setStateFunction(() => foundMovies = foundMoviesNew);
      globalKey = new GlobalKey();

      if (ServiceAgent.showLoadingAd) userState!.increaseAiRequestsCount();

      notFound = foundMovies.isEmpty;
    }

    setStateFunction(() => isLoading = currentQuery != queryToDebounce);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
      SizedBox(
        width: 10,
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        if (userState != null) {
          userState!.shouldRequestReview = true;
        }

        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    RatingHelper.refreshMoviesRating(foundMovies, context);

    final resultsWidget = getResultsWidget(query, true);

    return resultsWidget;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    RatingHelper.refreshMoviesRating(foundMovies, context);

    final resultsWidget = getResultsWidget(query, false);

    return resultsWidget;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme;
  }
}
