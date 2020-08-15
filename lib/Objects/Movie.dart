import 'package:mmobile/Enums/MovieType.dart';
import 'Person.dart';

class Movie {
  final String id;
  final String title;
  final String overview;
  final String tagline;
  final String posterPath;
  final int duration;
  int rating;
  int allVotes;
  int likedVotes;
  int dislikedVotes;
  final String countries;
  final List<String> actors;
  final List<String> directors;
  final List<String> genres;
  int movieRate;
  final MovieType movieType;
  final int year;
  final int averageTimeOfEpisode;
  final bool inProduction;
  final int seasonsCount;
  final double imdbRate;
  final int imdbVotes;

  Movie({this.id, this.title, this.overview, this.tagline, this.posterPath,
    this.duration, this.rating, this.allVotes, this.likedVotes, this.dislikedVotes, this.countries, this.actors, this.directors,
    this.genres, this.movieRate, this.movieType, this.year, this.averageTimeOfEpisode,
    this.inProduction, this.seasonsCount, this.imdbRate, this.imdbVotes});

  //  TODO: Map json class fields
  factory Movie.fromJson(Map<String, dynamic> json) {
//    var actors = json['actors'].map((model) {
//      return Person.fromJson(model);
//    }).toList().cast<Person>();
//
//    var directors = json['directors'].map((model) {
//      return Person.fromJson(model);
//    }).toList().cast<Person>();
    var actors = json['actors'].cast<String>();
    var directors = json['directors'].cast<String>();

    int likedVotes = json['likedVotes'];
    int dislikedVotes = json['unlikedVotes'];

    return Movie(
        id: json['id'],
        title: json['title'],
        tagline: json['tagline'],
        overview: json['overview'],
        posterPath: json['posterPath'],
        genres: json['genres'].cast<String>(),
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

  static int getMovieRating(int likedVotes, int dislikedVotes) {
    final result = likedVotes + dislikedVotes != 0
        ? (100 / (likedVotes + dislikedVotes)) * likedVotes : 0;

    return result.toInt();
  }
}