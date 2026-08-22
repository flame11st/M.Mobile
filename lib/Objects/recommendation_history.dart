import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';
import 'package:mmobile/Objects/movie.dart';

class RecommendationHistoryPageData {
  const RecommendationHistoryPageData({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    this.legacyArchive,
  });

  final List<RecommendationHistoryBatchSummary> items;
  final int nextCursor;
  final bool hasMore;
  final RecommendationHistoryLegacySummary? legacyArchive;

  factory RecommendationHistoryPageData.fromJson(Map<String, dynamic> json) {
    return RecommendationHistoryPageData(
      items: _maps(json['items'])
          .map(RecommendationHistoryBatchSummary.fromJson)
          .toList(growable: false),
      nextCursor: _int(json['nextCursor']),
      hasMore: json['hasMore'] == true,
      legacyArchive: json['legacyArchive'] is Map
          ? RecommendationHistoryLegacySummary.fromJson(
              Map<String, dynamic>.from(json['legacyArchive'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(growable: false),
        'nextCursor': nextCursor,
        'hasMore': hasMore,
        'legacyArchive': legacyArchive?.toJson(),
      };
}

class RecommendationHistoryBatchSummary {
  const RecommendationHistoryBatchSummary({
    required this.batchId,
    required this.generatedAt,
    required this.movieType,
    required this.discoveryLevel,
    required this.itemCount,
    required this.previewItems,
    this.ratingsVersion,
    this.promptVersion,
    this.scoreVersion,
    this.model,
  });

  final String batchId;
  final DateTime generatedAt;
  final MovieType movieType;
  final RecommendationDiscoveryLevel discoveryLevel;
  final int itemCount;
  final List<Movie> previewItems;
  final String? ratingsVersion;
  final String? promptVersion;
  final String? scoreVersion;
  final String? model;

  factory RecommendationHistoryBatchSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecommendationHistoryBatchSummary(
      batchId: '${json['batchId'] ?? ''}',
      generatedAt: DateTime.tryParse('${json['generatedAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      movieType: _movieType(json['movieType']),
      discoveryLevel: _discoveryLevel(json['discoveryLevel']),
      itemCount: _int(json['itemCount']),
      previewItems: _maps(json['previewItems'])
          .map(Movie.fromJson)
          .toList(growable: false),
      ratingsVersion: _nullableString(json['ratingsVersion']),
      promptVersion: _nullableString(json['promptVersion']),
      scoreVersion: _nullableString(json['scoreVersion']),
      model: _nullableString(json['model']),
    );
  }

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'generatedAt': generatedAt.toIso8601String(),
        'movieType': movieType.index,
        'discoveryLevel': discoveryLevel.index,
        'itemCount': itemCount,
        'previewItems':
            previewItems.map((movie) => movie.toJson()).toList(growable: false),
        'ratingsVersion': ratingsVersion,
        'promptVersion': promptVersion,
        'scoreVersion': scoreVersion,
        'model': model,
      };
}

class RecommendationHistoryLegacySummary {
  const RecommendationHistoryLegacySummary({
    required this.itemCount,
    required this.previewItems,
    this.latestAt,
  });

  final DateTime? latestAt;
  final int itemCount;
  final List<Movie> previewItems;

  factory RecommendationHistoryLegacySummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecommendationHistoryLegacySummary(
      latestAt: DateTime.tryParse('${json['latestAt'] ?? ''}'),
      itemCount: _int(json['itemCount']),
      previewItems: _maps(json['previewItems'])
          .map(Movie.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'latestAt': latestAt?.toIso8601String(),
        'itemCount': itemCount,
        'previewItems':
            previewItems.map((movie) => movie.toJson()).toList(growable: false),
      };
}

class RecommendationHistoryBatchDetail {
  const RecommendationHistoryBatchDetail({
    required this.batchId,
    required this.generatedAt,
    required this.movieType,
    required this.discoveryLevel,
    required this.itemCount,
    required this.items,
    this.ratingsVersion,
    this.promptVersion,
    this.scoreVersion,
    this.model,
  });

  final String batchId;
  final DateTime generatedAt;
  final MovieType movieType;
  final RecommendationDiscoveryLevel discoveryLevel;
  final int itemCount;
  final List<RecommendationHistoryItem> items;
  final String? ratingsVersion;
  final String? promptVersion;
  final String? scoreVersion;
  final String? model;

  factory RecommendationHistoryBatchDetail.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecommendationHistoryBatchDetail(
      batchId: '${json['batchId'] ?? ''}',
      generatedAt: DateTime.tryParse('${json['generatedAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      movieType: _movieType(json['movieType']),
      discoveryLevel: _discoveryLevel(json['discoveryLevel']),
      itemCount: _int(json['itemCount']),
      items: _maps(json['items'])
          .map(RecommendationHistoryItem.fromJson)
          .toList(growable: false),
      ratingsVersion: _nullableString(json['ratingsVersion']),
      promptVersion: _nullableString(json['promptVersion']),
      scoreVersion: _nullableString(json['scoreVersion']),
      model: _nullableString(json['model']),
    );
  }

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'generatedAt': generatedAt.toIso8601String(),
        'movieType': movieType.index,
        'discoveryLevel': discoveryLevel.index,
        'itemCount': itemCount,
        'items': items.map((item) => item.toJson()).toList(growable: false),
        'ratingsVersion': ratingsVersion,
        'promptVersion': promptVersion,
        'scoreVersion': scoreVersion,
        'model': model,
      };
}

class RecommendationHistoryLegacyPage {
  const RecommendationHistoryLegacyPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.totalCount,
  });

  final List<RecommendationHistoryItem> items;
  final int nextCursor;
  final bool hasMore;
  final int totalCount;

  factory RecommendationHistoryLegacyPage.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecommendationHistoryLegacyPage(
      items: _maps(json['items'])
          .map(RecommendationHistoryItem.fromJson)
          .toList(growable: false),
      nextCursor: _int(json['nextCursor']),
      hasMore: json['hasMore'] == true,
      totalCount: _int(json['totalCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(growable: false),
        'nextCursor': nextCursor,
        'hasMore': hasMore,
        'totalCount': totalCount,
      };
}

class RecommendationHistoryItem {
  const RecommendationHistoryItem({
    required this.rank,
    required this.movie,
    required this.userAction,
    this.matchLabel,
    this.rankScore = 0,
    this.explanation,
  });

  final int rank;
  final Movie movie;
  final String userAction;
  final String? matchLabel;
  final double rankScore;
  final String? explanation;

  factory RecommendationHistoryItem.fromJson(Map<String, dynamic> json) {
    final movieJson = json['movie'];
    return RecommendationHistoryItem(
      rank: _int(json['rank']),
      movie: Movie.fromJson(
        movieJson is Map
            ? Map<String, dynamic>.from(movieJson)
            : <String, dynamic>{},
      ),
      userAction: '${json['userAction'] ?? 'none'}',
      matchLabel: _nullableString(json['matchLabel']),
      rankScore: (json['rankScore'] as num?)?.toDouble() ?? 0,
      explanation: _nullableString(json['explanation']),
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'movie': movie.toJson(),
        'userAction': userAction,
        'matchLabel': matchLabel,
        'rankScore': rankScore,
        'explanation': explanation,
      };
}

Iterable<Map<String, dynamic>> _maps(dynamic value) sync* {
  if (value is! Iterable) {
    return;
  }
  for (final item in value) {
    if (item is Map) {
      yield Map<String, dynamic>.from(item);
    }
  }
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

String? _nullableString(dynamic value) {
  final text = '${value ?? ''}'.trim();
  return text.isEmpty ? null : text;
}

MovieType _movieType(dynamic value) {
  final index = _int(value);
  return index >= 0 && index < MovieType.values.length
      ? MovieType.values[index]
      : MovieType.movie;
}

RecommendationDiscoveryLevel _discoveryLevel(dynamic value) {
  final index = _int(value);
  return index >= 0 && index < RecommendationDiscoveryLevel.values.length
      ? RecommendationDiscoveryLevel.values[index]
      : RecommendationDiscoveryLevel.balanced;
}
