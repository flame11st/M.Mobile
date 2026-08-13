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
  final int requestedCount;
  final int availableCount;
  final bool isPartial;
  final bool alternativesExhausted;

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
    this.requestedCount = 10,
    this.availableCount = 0,
    this.isPartial = false,
    this.alternativesExhausted = false,
  });

  factory RecommendationDiscoverySession.fromJson(Map<String, dynamic> json) {
    final itemModels = json['items'] is Iterable ? json['items'] : [];

    final items =
        itemModels.map<Movie>((model) => Movie.fromJson(model)).toList();

    return RecommendationDiscoverySession(
      sessionId: json['sessionId'],
      batchId: json['batchId'],
      movieType: MovieType.values[json['movieType'] ?? 0],
      discoveryLevel:
          RecommendationDiscoveryLevel.values[json['discoveryLevel'] ?? 0],
      expiresAt:
          json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt']),
      items: items,
      nextCursor: json['nextCursor'] ?? 0,
      hasMore: json['hasMore'] ?? false,
      pageSize: json['pageSize'] ?? 10,
      requestedCount: json['requestedCount'] ?? json['pageSize'] ?? 10,
      availableCount: json['availableCount'] ?? items.length,
      isPartial: json['isPartial'] ?? false,
      alternativesExhausted: json['alternativesExhausted'] ?? false,
    );
  }
}
