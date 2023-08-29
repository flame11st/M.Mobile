import 'dart:convert';

import 'package:mmobile/Enums/MovieListType.dart';
import 'package:mmobile/Objects/Movie.dart';

class MoviesList {
  String name;
  final int order;

  final MovieListType movieListType;
  List<Movie> listMovies;

  MoviesList({required this.name, required this.order, required this.listMovies, required this.movieListType});

  factory MoviesList.fromJson(Map<String, dynamic> json) {
    Iterable iterableMovies = json['listMovies'] is Iterable
        ? json['listMovies']
        : jsonDecode(json['listMovies']);

    List<Movie> movies = iterableMovies.map((model) {
      return Movie.fromJson(model);
    }).toList();

    return MoviesList(
        name: json['name'],
        order: json['order'],
        movieListType: MovieListType.values[json['movieListType']],
        listMovies: movies);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'order': order,
        'listMovies': json.encode(listMovies),
        'movieListType': movieListType.index
      };
}
