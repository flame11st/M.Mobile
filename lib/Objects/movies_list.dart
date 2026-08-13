import 'dart:convert';

import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Objects/movie.dart';

class MoviesList {
  String name;
  final int order;
  final MovieListType movieListType;
  final String? sourceKey;
  final DateTime? sourceUpdatedAt;
  List<Movie> listMovies;

  MoviesList({
    required this.name,
    required this.order,
    required this.listMovies,
    required this.movieListType,
    this.sourceKey,
    this.sourceUpdatedAt,
  });

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
      sourceKey: _readSourceKey(json),
      sourceUpdatedAt: _readSourceUpdatedAt(json),
      listMovies: movies,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'order': order,
        'listMovies': json.encode(listMovies),
        'movieListType': movieListType.index,
        if (sourceKey != null) 'sourceKey': sourceKey,
        if (sourceUpdatedAt != null)
          'sourceUpdatedAt': sourceUpdatedAt!.toUtc().toIso8601String(),
      };

  static String? _readSourceKey(Map<String, dynamic> json) {
    final value = json['sourceKey'] ?? json['source'] ?? json['provider'];
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static DateTime? _readSourceUpdatedAt(Map<String, dynamic> json) {
    final value = json['sourceUpdatedAt'] ??
        json['sourceUpdated'] ??
        json['updatedAt'] ??
        json['updated'];
    return value == null ? null : DateTime.tryParse(value.toString());
  }
}
