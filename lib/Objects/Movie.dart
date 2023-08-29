import 'dart:convert';

import 'package:mmobile/Enums/MovieType.dart';

class Movie {
  final String id;
  String title;
  String overview;
  String? tagline;
  String posterPath;
  int duration;
  int rating;
  int allVotes;
  int likedVotes;
  int dislikedVotes;
  String countries;
  List<String> actors;
  List<String> directors;
  List<String> genres;
  int movieRate;
  MovieType movieType;
  DateTime releaseDate;
  DateTime? updated;
  int averageTimeOfEpisode;
  bool inProduction;
  int seasonsCount;
  double imdbRate;
  int imdbVotes;

  updateMovie(Movie updatedMovie) {
    if (updatedMovie.id != this.id) return;

    this.title = updatedMovie.title;
    this.overview = updatedMovie.overview;
    this.tagline = updatedMovie.tagline;
    this.posterPath = updatedMovie.posterPath;
    this.duration = updatedMovie.duration;
    this.rating = updatedMovie.rating;
    this.allVotes = updatedMovie.allVotes;
    this.likedVotes = updatedMovie.likedVotes;
    this.dislikedVotes = updatedMovie.dislikedVotes;
    this.countries = updatedMovie.countries;
    this.actors = updatedMovie.actors;
    this.directors = updatedMovie.directors;
    this.genres = updatedMovie.genres;
    this.movieRate = updatedMovie.movieRate;
    this.movieType = updatedMovie.movieType;
    this.releaseDate = updatedMovie.releaseDate;
    this.averageTimeOfEpisode = updatedMovie.averageTimeOfEpisode;
    this.inProduction = updatedMovie.inProduction;
    this.seasonsCount = updatedMovie.seasonsCount;
    this.imdbRate = updatedMovie.imdbRate;
    this.imdbVotes = updatedMovie.imdbVotes;
    this.updated = updatedMovie.updated;
  }

  Movie(
      {required this.id,
        required this.title,
        required this.overview,
        required this.tagline,
        required this.posterPath,
        required this.duration,
        required this.rating,
        required this.allVotes,
        required this.likedVotes,
        required this.dislikedVotes,
        required this.countries,
        required this.actors,
        required this.directors,
        required this.genres,
        required this.movieRate,
        required this.movieType,
        required this.releaseDate,
        required this.averageTimeOfEpisode,
        required this.inProduction,
        required this.seasonsCount,
        required this.imdbRate,
        required this.imdbVotes,
        this.updated});

  factory Movie.fromJson(Map<String, dynamic> json) {
    var actors = json['actors'] is Iterable
        ? json['actors'].cast<String>()
        : jsonDecode(json['actors']).cast<String>();
    var directors = json['directors'] is List
        ? json['directors'].cast<String>()
        : jsonDecode(json['directors']).cast<String>();
    var genres = json['genres'] is List
        ? json['genres'].cast<String>()
        : jsonDecode(json['genres']).cast<String>();
    var updated =
        json['updated'] == null ? null : DateTime.parse(json['updated']);

    var imdbRate = json['imdbRate'] > 10 ? json['imdbRate'] / 10 : json['imdbRate'] / 1;

    int likedVotes = json['likedVotes'];
    int dislikedVotes = json['unlikedVotes'];
    //
    // if (json['title'] == 'The Grand Budapest Hotel') {
    //   likedVotes = 103000;
    //   dislikedVotes = 9358;
    // }

    return Movie(
        id: json['id'],
        title: json['title'],
        tagline: json['tagline'],
        overview: json['overview'],
        posterPath: json['posterPath'],
        genres: genres,
        releaseDate: DateTime.parse(json['releaseDate']),
        duration: json['duration'],
        rating: getMovieRating(likedVotes, dislikedVotes),
        allVotes: likedVotes + dislikedVotes,
        likedVotes: likedVotes,
        dislikedVotes: dislikedVotes,
        movieRate: json['movieRate'],
        movieType: MovieType.values[json['movieType']],
        countries: json['countries'],
        actors: actors,
        directors: directors,
        seasonsCount: json['seasonsCount'],
        averageTimeOfEpisode: json['averageTimeOfEpisode'],
        inProduction: json['inProduction'],
        imdbRate: imdbRate,
        imdbVotes: json['imdbVotes'],
        updated: updated);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tagline': tagline,
        'overview': overview,
        'posterPath': posterPath,
        'genres': jsonEncode(genres),
        'releaseDate': releaseDate.toString(),
        'duration': duration,
        'likedVotes': likedVotes,
        'unlikedVotes': dislikedVotes,
        'movieRate': movieRate,
        'movieType': movieType.index,
        'countries': countries,
        'actors': jsonEncode(actors),
        'directors': jsonEncode(directors),
        'seasonsCount': seasonsCount,
        'averageTimeOfEpisode': averageTimeOfEpisode,
        'inProduction': inProduction,
        'imdbRate': imdbRate,
        'imdbVotes': imdbVotes,
        'updated': updated.toString()
      };

  static int getMovieRating(int likedVotes, int dislikedVotes) {
    final result = likedVotes + dislikedVotes != 0
        ? (100 / (likedVotes + dislikedVotes)) * likedVotes
        : 0;

    return result.toInt();
  }
}
