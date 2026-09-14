import 'dart:convert';

import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';

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
  String? scoreSource;
  double? scoreValue;
  String? scoreScale;
  int? scoreCount;
  int recommendationMatchPercent;
  String? recommendationMatchLabel;
  double recommendationRankScore;
  String? recommendationReason;
  String? recommendationScoreVersion;
  String? recommendationPromptVersion;
  DateTime? recommendationGeneratedAt;
  RecommendationDiscoveryLevel? recommendationDiscoveryLevel;

  updateMovie(Movie updatedMovie) {
    if (updatedMovie.id != id) return;

    title = updatedMovie.title;
    overview = updatedMovie.overview;
    tagline = updatedMovie.tagline;
    posterPath = updatedMovie.posterPath;
    duration = updatedMovie.duration;
    rating = updatedMovie.rating;
    allVotes = updatedMovie.allVotes;
    likedVotes = updatedMovie.likedVotes;
    dislikedVotes = updatedMovie.dislikedVotes;
    countries = updatedMovie.countries;
    actors = updatedMovie.actors;
    directors = updatedMovie.directors;
    genres = updatedMovie.genres;
    movieRate = updatedMovie.movieRate;
    movieType = updatedMovie.movieType;
    releaseDate = updatedMovie.releaseDate;
    averageTimeOfEpisode = updatedMovie.averageTimeOfEpisode;
    inProduction = updatedMovie.inProduction;
    seasonsCount = updatedMovie.seasonsCount;
    imdbRate = updatedMovie.imdbRate;
    imdbVotes = updatedMovie.imdbVotes;
    scoreSource = updatedMovie.scoreSource;
    scoreValue = updatedMovie.scoreValue;
    scoreScale = updatedMovie.scoreScale;
    scoreCount = updatedMovie.scoreCount;
    recommendationMatchPercent = updatedMovie.recommendationMatchPercent;
    recommendationMatchLabel = updatedMovie.recommendationMatchLabel;
    recommendationRankScore = updatedMovie.recommendationRankScore;
    recommendationReason = updatedMovie.recommendationReason;
    recommendationScoreVersion = updatedMovie.recommendationScoreVersion;
    recommendationPromptVersion = updatedMovie.recommendationPromptVersion;
    recommendationGeneratedAt = updatedMovie.recommendationGeneratedAt;
    recommendationDiscoveryLevel = updatedMovie.recommendationDiscoveryLevel;
    updated = updatedMovie.updated;
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
      this.scoreSource,
      this.scoreValue,
      this.scoreScale,
      this.scoreCount,
      this.recommendationMatchPercent = 0,
      this.recommendationMatchLabel,
      this.recommendationRankScore = 0,
      this.recommendationReason,
      this.recommendationScoreVersion,
      this.recommendationPromptVersion,
      this.recommendationGeneratedAt,
      this.recommendationDiscoveryLevel,
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
    final updatedValue = '${json['updated'] ?? ''}'.trim();
    final updated = updatedValue.isEmpty || updatedValue == 'null'
        ? null
        : DateTime.tryParse(updatedValue);

    var imdbRate =
        json['imdbRate'] > 10 ? json['imdbRate'] / 10 : json['imdbRate'] / 1;

    int likedVotes = json['likedVotes'];
    int dislikedVotes = json['unlikedVotes'];
    final movieDiaryVoteCount = likedVotes + dislikedVotes;
    final explicitScoreSource = _nullableString(json['scoreSource']);
    final explicitScoreValue = (json['scoreValue'] as num?)?.toDouble();
    final explicitScoreScale = _nullableString(json['scoreScale']);
    final explicitScoreCount = (json['scoreCount'] as num?)?.toInt();
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
        posterPath: '${json['posterPath'] ?? ''}'.trim(),
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
        scoreSource: explicitScoreSource ??
            (movieDiaryVoteCount > 0
                ? 'MovieDiary'
                : imdbRate > 0 && json['imdbVotes'] > 0
                    ? 'IMDb'
                    : null),
        scoreValue: explicitScoreSource != null
            ? explicitScoreValue
            : movieDiaryVoteCount > 0
                ? getMovieRating(likedVotes, dislikedVotes).toDouble()
                : imdbRate > 0 && json['imdbVotes'] > 0
                    ? imdbRate
                    : null,
        scoreScale: explicitScoreSource != null
            ? explicitScoreScale
            : movieDiaryVoteCount > 0
                ? 'percent'
                : imdbRate > 0 && json['imdbVotes'] > 0
                    ? '10'
                    : null,
        scoreCount: explicitScoreSource != null
            ? explicitScoreCount
            : movieDiaryVoteCount > 0
                ? movieDiaryVoteCount
                : imdbRate > 0 && json['imdbVotes'] > 0
                    ? json['imdbVotes']
                    : null,
        recommendationMatchPercent: json['recommendationMatchPercent'] ?? 0,
        recommendationMatchLabel: _readRecommendationMatchLabel(json),
        recommendationRankScore:
            (json['recommendationRankScore'] as num?)?.toDouble() ?? 0,
        recommendationReason: json['recommendationReason'],
        recommendationScoreVersion: json['recommendationScoreVersion'],
        recommendationPromptVersion: json['recommendationPromptVersion'],
        recommendationGeneratedAt:
            DateTime.tryParse('${json['recommendationGeneratedAt'] ?? ''}'),
        recommendationDiscoveryLevel:
            json['recommendationDiscoveryLevel'] == null
                ? null
                : RecommendationDiscoveryLevel
                    .values[json['recommendationDiscoveryLevel']],
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
        'scoreSource': scoreSource,
        'scoreValue': scoreValue,
        'scoreScale': scoreScale,
        'scoreCount': scoreCount,
        'recommendationMatchPercent': recommendationMatchPercent,
        'recommendationMatchLabel': recommendationMatchLabel,
        'recommendationRankScore': recommendationRankScore,
        'recommendationReason': recommendationReason,
        'recommendationScoreVersion': recommendationScoreVersion,
        'recommendationPromptVersion': recommendationPromptVersion,
        'recommendationGeneratedAt':
            recommendationGeneratedAt?.toIso8601String(),
        'recommendationDiscoveryLevel': recommendationDiscoveryLevel?.index,
        'updated': updated?.toIso8601String()
      };

  static String? _readRecommendationMatchLabel(Map<String, dynamic> json) {
    final label = '${json['recommendationMatchLabel'] ?? ''}'.trim();
    if (label.isNotEmpty) {
      return label;
    }

    final legacyPercent = json['recommendationMatchPercent'] as num?;
    return legacyPercent != null && legacyPercent > 0
        ? 'Worth exploring'
        : null;
  }

  static String? _nullableString(dynamic value) {
    final normalized = '${value ?? ''}'.trim();
    return normalized.isEmpty || normalized.toLowerCase() == 'null'
        ? null
        : normalized;
  }

  static int getMovieRating(int likedVotes, int dislikedVotes) {
    final result = likedVotes + dislikedVotes != 0
        ? (100 / (likedVotes + dislikedVotes)) * likedVotes
        : 0;

    return result.toInt();
  }
}
