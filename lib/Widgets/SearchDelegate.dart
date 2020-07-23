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

  searchMovies(BuildContext context, StateSetter setState) async {
    isLoading = true;

    if (userState == null) {
      userState = Provider.of<UserState>(context);
      serviceAgent.state = userState;
    }

    final moviesState = Provider.of<MoviesState>(context);

    // Debounce
    final queryToDebounce = query;
    await Future.delayed(Duration(milliseconds: 500));
    if (queryToDebounce != query) {
      return;
    }

    final moviesResponse = await serviceAgent.search(query);

    if (moviesResponse.statusCode == 200) {
      Iterable iterableMovies = json.decode(moviesResponse.body);
      final foundMovies = iterableMovies.map((model) {
        return MovieSearchDTO.fromJson(model);
      }).map((movie) {
        final userMoviesList = moviesState.userMovies.where((um) => um.id == movie.id);

        if(userMoviesList.length > 0) {
          movie.movieRate = userMoviesList.first.movieRate;
        }

        return movie;
      }).toList();

      isLoading = false;
      setState(() => this.foundMovies = foundMovies);
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
    return Container(
        color: MColors.PrimaryColor,
        child: ListView(
          children: <Widget>[
            for (final movie in foundMovies) MovieSearchItem(movie: movie)
          ],
        ));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        if (query == '') {
          oldQuery = '';
          isLoading = false;
          setState(() => foundMovies.clear());
        } else if (query != oldQuery) {
          oldQuery = query;
          searchMovies(context, setState);
        }

        return Container(
            color: Theme.of(context).primaryColor,
            child: ListView(
              children: <Widget>[
                if (isLoading) LinearProgressIndicator(),
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
