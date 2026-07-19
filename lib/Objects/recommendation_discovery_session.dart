import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';
import 'package:mmobile/Objects/movie.dart';

class RecommendationDiscoverySession {
  final String sessionId;
  final String batchId;
  final MovieType movieType;
  final RecommendationDiscoveryLevel discoveryLevel;
  final DateTime? expiresAt;
  final List<Movie> items;
  final int nextCursor;
  final bool hasMore;
  final int pageSize;

  const RecommendationDiscoverySession({
    required this.sessionId,
    required this.batchId,
    required this.movieType,
    required this.discoveryLevel,
    required this.expiresAt,
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.pageSize,
  });

  factory RecommendationDiscoverySession.fromJson(Map<String, dynamic> json) {
    final itemModels = json['items'] is Iterable ? json['items'] : [];

    return RecommendationDiscoverySession(
      sessionId: json['sessionId'],
      batchId: json['batchId'],
      movieType: MovieType.values[json['movieType'] ?? 0],
      discoveryLevel:
          RecommendationDiscoveryLevel.values[json['discoveryLevel'] ?? 0],
      expiresAt:
          json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt']),
      items: itemModels.map<Movie>((model) => Movie.fromJson(model)).toList(),
      nextCursor: json['nextCursor'] ?? 0,
      hasMore: json['hasMore'] ?? false,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}
