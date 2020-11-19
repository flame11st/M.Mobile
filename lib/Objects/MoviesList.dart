import 'dart:convert';

import 'package:mmobile/Objects/Movie.dart';

class MoviesList {
  final String name;
  final int order;
  List<Movie> listMovies;

  MoviesList({this.name, this.order, this.listMovies});

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
        listMovies: movies);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'order': order,
    'listMovies': json.encode(listMovies),
  };
}
