import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/MovieSearchItem.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:provider/provider.dart';
import 'MovieListItem.dart';
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

      if (query == '') {
        oldQuery = '';
        isLoading = false;
        setState(() => notFound = false);
        setState(() => foundMovies.clear());
      } else if (query != oldQuery) {
        oldQuery = query;
        searchMovies(context);
      }

      GlobalKey globalKey = new GlobalKey();

      if (ModalRoute.of(context).isCurrent) {
        MyGlobals.activeKey = globalKey;
      }

      return Container(
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
                        "You can search in English, German and Russian languages.",
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    )),
              for (final movie in foundMovies) MovieListItem(movie: movie),
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

    // Debounce
    final queryToDebounce = query;
    await Future.delayed(Duration(milliseconds: 1500));
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
      }).toList();

      refreshMoviesRating(foundMovies, context);

      setStateFunction(() => this.foundMovies = foundMovies);

      notFound = foundMovies.isEmpty;
    }

    isLoading = currentQuery != queryToDebounce;
  }

  refreshMoviesRating(List<Movie> movies, BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);

    movies.forEach((movie) {
      final userMoviesList =
      moviesState.userMovies.where((um) => um.id == movie.id);

      if (userMoviesList.length > 0) {
        movie.movieRate = userMoviesList.first.movieRate;
      } else {
        movie.movieRate = 0;
      }
    });
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
          userState.shouldRequestReview = true;
        }

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
    refreshMoviesRating(foundMovies, context);

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
