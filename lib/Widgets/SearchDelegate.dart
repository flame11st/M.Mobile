import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mmobile/Objects/MovieSearchDTO.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/MovieSearchItem.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';

class MSearchDelegate extends SearchDelegate {
  List<MovieSearchDTO> foundMovies = new List<MovieSearchDTO>();
  final serviceAgent = new ServiceAgent();
  UserState userState;
  String oldQuery;
  bool isLoading = false;
  StateSetter setStateFunction;
  int searchTimestamp;

  searchMovies(BuildContext context) async {
    isLoading = true;

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

    final moviesResponse = await serviceAgent.search(query);

    if (searchTimestamp!= null && timestamp < searchTimestamp) return;

    if (moviesResponse.statusCode == 200) {
      searchTimestamp = timestamp;

      Iterable iterableMovies = json.decode(moviesResponse.body);
      final foundMovies = iterableMovies.map((model) {
        return MovieSearchDTO.fromJson(model);
      }).map((movie) {
        final userMoviesList =
            moviesState.userMovies.where((um) => um.id == movie.id);

        if (userMoviesList.length > 0) {
          movie.movieRate = userMoviesList.first.movieRate;
        }

        return movie;
      }).toList();

      isLoading = false;
      setStateFunction(() => this.foundMovies = foundMovies);
    } else {
      isLoading = false;
    }
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
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      this.setStateFunction = setState;
      return Container(
          color: Theme.of(context).primaryColor,
          child: ListView(
            children: <Widget>[
              SizedBox(
                  height: 5,
                  child: isLoading ? LinearProgressIndicator() : Text('')),
              for (final movie in foundMovies) MovieSearchItem(movie: movie)
            ],
          ));
    });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      this.setStateFunction = setState;

      if (query == '') {
        oldQuery = '';
        isLoading = false;
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
              for (final movie in foundMovies) MovieSearchItem(movie: movie)
            ],
          ));
    });
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme;
  }
}
