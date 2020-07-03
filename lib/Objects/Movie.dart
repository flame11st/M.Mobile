import 'package:mmobile/Enums/MovieType.dart';
import 'Person.dart';

class Movie {
    final String id;
    final String title;
    final String overview;
    final String tagline;
    final String posterPath;
    final int duration;
    final int rating;
    final int scores;
    final String countries;
    final List<Person> actors;
    final List<Person> directors;
    final List<String> genres;
    final int movieRate;
    final MovieType movieType;
    final int year;
    final int averageTimeOfEpisode;
    final bool inProduction;
    final int seasonsCount;

    Movie({this.id, this.title, this.overview, this.tagline, this.posterPath,
        this.duration, this.rating, this.scores, this.countries, this.actors, this.directors,
        this.genres, this.movieRate, this.movieType, this.year, this.averageTimeOfEpisode,
        this.inProduction, this.seasonsCount});

    //  TODO: Map json class fields
    factory Movie.fromJson(Map<String, dynamic> json) {
        return Movie(
            id: json['id'],
            title: json['title'],
            tagline: json['tagline'],
            overview: json['overview'],
            posterPath: json['posterPath'],
            genres: json['genres'].cast<String>(),
            year: json['year'],
            duration: json['duration'],
            rating: json['rating'],
            scores: json['scores'],
            movieRate: json['movieRate'],
            movieType: MovieType.values[json['movieType']],
            countries: json['countries'],
            actors: new List<Person>(),
            directors: new List<Person>(),
            seasonsCount: json['seasonsCount'],
            averageTimeOfEpisode: json['averageTimeOfEpisode'],
            inProduction: json['inProduction'],
        );
    }
}