import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MovieSearchDTO.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Widgets/MovieSearchItem.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';

class MSearchDelegate extends SearchDelegate {
  List<Movie> foundMovies = new List<Movie>();
  final serviceAgent = new ServiceAgent();
  UserState userState;
  String oldQuery;
  String currentQuery;
  bool isLoading = false;
  StateSetter setStateFunction;
  StateSetter setStateSwitcherFunction;
  int searchTimestamp;
  bool notFound = false;
  bool showAdvancedCard = false;
  bool isAdvanced = false;

  setAdvacedSearch() {
    setStateFunction(() => isLoading = !isLoading);
  }

  getResultsWidget(String query) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      this.setStateFunction = setState;
      final moviesState = Provider.of<MoviesState>(context);

      if (query == '') {
        oldQuery = '';
        isLoading = false;
        setState(() => notFound = false);
        setState(() => foundMovies.clear());
      } else if (query != oldQuery) {
        oldQuery = query;
        searchMovies(context);
      }

      return Container(
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
                        "You can search in English, German and Russian languages."
                        "${isAdvanced ? "\n\nAdvanced search may take longer, but will find anything you want" : ""}",
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    )),
              // for (final movie in foundMovies) MovieSearchItem(movie: movie, imageBaseUrl: moviesState.imageBaseUrl),
              for (final movie in foundMovies) MovieSearchItem(movie: movie),
              // if (!isAdvanced &&
              //     (foundMovies.isNotEmpty || notFound) &&
              //     !isLoading)
              //   MCard(
              //       marginTop: 15,
              //       marginLR: 10,
              //       marginBottom: 10,
              //       child: Container(
              //           width: MediaQuery.of(context).size.width,
              //           child: Column(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               Text(
              //                 "Didn't find what you were looking for?",
              //                 style: Theme.of(context).textTheme.headline2,
              //               ),
              //               SizedBox(
              //                 height: 15,
              //               ),
              //               MButton(
              //                 prependIcon: Icons.search,
              //                 active: true,
              //                 text: "Advanced Search",
              //                 width: 200,
              //                 onPressedCallback: () {
              //                   setStateSwitcherFunction(
              //                       () {
              //                         notFound = false;
              //                         isAdvanced = true;
              //                       });
              //                   foundMovies.clear();
              //                   searchMovies(context);
              //                 },
              //               ),
              //             ],
              //           ))),
            ],
          ));
    });
  }

  searchMovies(BuildContext context) async {
    currentQuery = query;
    setStateFunction(() => isLoading = true);

    if (userState == null) {
      userState = Provider.of<UserState>(context);
      serviceAgent.state = userState;
    }

    final moviesState = Provider.of<MoviesState>(context);

    // Debounce
    final queryToDebounce = query;
    await Future.delayed(Duration(milliseconds: 700));
    if (queryToDebounce != query) return;

    var timestamp = DateTime.now().millisecondsSinceEpoch;

    var moviesResponse;

    if (isAdvanced) {
      moviesResponse = await serviceAgent.advancedSearch(query);
    } else {
      moviesResponse = await serviceAgent.search(query);
    }

    if (searchTimestamp != null && timestamp < searchTimestamp) return;

    if (moviesResponse.statusCode == 200) {
      searchTimestamp = timestamp;

      Iterable iterableMovies = json.decode(moviesResponse.body);
      final foundMovies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).map((movie) {
        final userMoviesList =
            moviesState.userMovies.where((um) => um.id == movie.id);

        if (userMoviesList.length > 0) {
          movie.movieRate = userMoviesList.first.movieRate;
        }

        return movie;
      }).toList();

      setStateFunction(() => this.foundMovies = foundMovies);

      notFound = foundMovies.isEmpty;
    }

    isLoading = currentQuery != queryToDebounce;
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
      // Column(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: [
      //     Text(
      //       'Advanced',
      //       style: Theme.of(context).textTheme.headline3,
      //     ),
      //     SizedBox(
      //         height: 24,
      //         child: StatefulBuilder(
      //           builder: (BuildContext context, StateSetter setState) {
      //             setStateSwitcherFunction = setState;
      //             return Switch(
      //                 value: this.isAdvanced,
      //                 onChanged: (bool value) {
      //                   setState(() => isAdvanced = !isAdvanced);
      //                   searchMovies(context);
      //                 });
      //           },
      //         ))
      //   ],
      // ),
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
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final resultsWidget = getResultsWidget(query);

    return resultsWidget;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final resultsWidget = getResultsWidget(query);

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
