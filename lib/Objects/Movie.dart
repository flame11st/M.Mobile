import 'dart:convert';

import 'package:mmobile/Enums/MovieType.dart';
import 'Person.dart';

class Movie {
  final String id;
  String title;
  String overview;
  String tagline;
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
  int year;
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
    this.year = updatedMovie.year;
    this.averageTimeOfEpisode = updatedMovie.averageTimeOfEpisode;
    this.inProduction = updatedMovie.inProduction;
    this.seasonsCount = updatedMovie.seasonsCount;
    this.imdbRate = updatedMovie.imdbRate;
    this.imdbVotes = updatedMovie.imdbVotes;
  }

  Movie({this.id, this.title, this.overview, this.tagline, this.posterPath,
    this.duration, this.rating, this.allVotes, this.likedVotes, this.dislikedVotes, this.countries, this.actors, this.directors,
    this.genres, this.movieRate, this.movieType, this.year, this.averageTimeOfEpisode,
    this.inProduction, this.seasonsCount, this.imdbRate, this.imdbVotes});

  factory Movie.fromJson(Map<String, dynamic> json) {
    var actors = json['actors'] is Iterable ? json['actors'].cast<String>() : jsonDecode(json['actors']).cast<String>();
    var directors = json['directors'] is List ? json['directors'].cast<String>() : jsonDecode(json['directors']).cast<String>();
    var genres = json['genres'] is List ? json['genres'].cast<String>() : jsonDecode(json['genres']).cast<String>();

    int likedVotes = json['likedVotes'];
    int dislikedVotes = json['unlikedVotes'];

    return Movie(
        id: json['id'],
        title: json['title'],
        tagline: json['tagline'],
        overview: json['overview'],
        posterPath: json['posterPath'],
        genres: genres,
        year: json['year'],
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
        imdbRate: json['imdbRate'] / 10,
        imdbVotes: json['imdbVotes']
    );
  }

  Map<String, dynamic> toJson() =>
          {
            'id': id,
            'title': title,
            'tagline': tagline,
            'overview': overview,
            'posterPath': posterPath,
            'genres': jsonEncode(genres),
            'year': year,
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
            'imdbRate': imdbRate *  10,
            'imdbVotes': imdbVotes
          };

  static int getMovieRating(int likedVotes, int dislikedVotes) {
    final result = likedVotes + dislikedVotes != 0
        ? (100 / (likedVotes + dislikedVotes)) * likedVotes : 0;

    return result.toInt();
  }
}