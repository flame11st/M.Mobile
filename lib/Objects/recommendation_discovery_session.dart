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
  final RecommendationDeckOrigin origin;
  final DateTime? generatedAt;
  final RecommendationAllowance? allowance;

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
    this.origin = RecommendationDeckOrigin.unknown,
    this.generatedAt,
    this.allowance,
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
      origin: RecommendationDeckOrigin.fromJson(json['origin']),
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.tryParse(json['generatedAt'].toString()),
      allowance: json['allowance'] is Map<String, dynamic>
          ? RecommendationAllowance.fromJson(
              json['allowance'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

enum RecommendationDeckOrigin {
  fresh,
  saved,
  recovered,
  session,
  unknown;

  static RecommendationDeckOrigin fromJson(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    return RecommendationDeckOrigin.values.firstWhere(
      (origin) => origin.name == normalized,
      orElse: () => RecommendationDeckOrigin.unknown,
    );
  }
}

class RecommendationAllowance {
  final bool limitReached;
  final bool isPremium;
  final bool meteringEnabled;
  final bool meteringAvailable;
  final bool rolloutConfigurationAvailable;
  final int rolloutConfigurationSchemaVersion;
  final String rolloutConfigurationOutcome;
  final bool requestInProgress;
  final int freeDecksPerDay;
  final int freeDecksUsed;
  final int freeDecksRemaining;
  final int rewardedDecksPerDay;
  final int rewardedDecksGranted;
  final int rewardedDecksUsed;
  final int rewardedCreditsAvailable;
  final int rewardedCreditsReserved;
  final DateTime? resetAtUtc;
  final List<RewardedDeckCreditTransition> rewardedCreditTransitions;

  const RecommendationAllowance({
    required this.limitReached,
    required this.isPremium,
    this.meteringEnabled = false,
    required this.meteringAvailable,
    this.rolloutConfigurationAvailable = false,
    this.rolloutConfigurationSchemaVersion = 0,
    this.rolloutConfigurationOutcome = 'safe_fallback',
    this.requestInProgress = false,
    required this.freeDecksPerDay,
    required this.freeDecksUsed,
    required this.freeDecksRemaining,
    this.rewardedDecksPerDay = 3,
    this.rewardedDecksGranted = 0,
    this.rewardedDecksUsed = 0,
    this.rewardedCreditsAvailable = 0,
    this.rewardedCreditsReserved = 0,
    required this.resetAtUtc,
    this.rewardedCreditTransitions = const [],
  });

  factory RecommendationAllowance.fromJson(Map<String, dynamic> json) {
    return RecommendationAllowance(
      limitReached: json['limitReached'] ?? false,
      isPremium: json['isPremium'] ?? false,
      meteringEnabled: json['meteringEnabled'] ?? false,
      meteringAvailable: json['meteringAvailable'] ?? true,
      rolloutConfigurationAvailable:
          json['rolloutConfigurationAvailable'] ?? false,
      rolloutConfigurationSchemaVersion:
          json['rolloutConfigurationSchemaVersion'] ?? 0,
      rolloutConfigurationOutcome:
          json['rolloutConfigurationOutcome']?.toString() ?? 'safe_fallback',
      requestInProgress: json['requestInProgress'] ?? false,
      freeDecksPerDay: json['freeDecksPerDay'] ?? 2,
      freeDecksUsed: json['freeDecksUsed'] ?? 0,
      freeDecksRemaining: json['freeDecksRemaining'] ?? 0,
      rewardedDecksPerDay: json['rewardedDecksPerDay'] ?? 3,
      rewardedDecksGranted: json['rewardedDecksGranted'] ?? 0,
      rewardedDecksUsed: json['rewardedDecksUsed'] ?? 0,
      rewardedCreditsAvailable: json['rewardedCreditsAvailable'] ?? 0,
      rewardedCreditsReserved: json['rewardedCreditsReserved'] ?? 0,
      resetAtUtc: json['resetAtUtc'] == null
          ? null
          : DateTime.tryParse(json['resetAtUtc']),
      rewardedCreditTransitions: json['rewardedCreditTransitions'] is Iterable
          ? (json['rewardedCreditTransitions'] as Iterable)
              .whereType<Map<String, dynamic>>()
              .map(RewardedDeckCreditTransition.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class RewardedDeckCreditTransition {
  const RewardedDeckCreditTransition({
    required this.transitionId,
    required this.type,
    required this.occurredAtUtc,
  });

  final String transitionId;
  final String type;
  final DateTime? occurredAtUtc;

  factory RewardedDeckCreditTransition.fromJson(Map<String, dynamic> json) =>
      RewardedDeckCreditTransition(
        transitionId: json['transitionId']?.toString() ?? '',
        type: json['type']?.toString().toLowerCase() ?? '',
        occurredAtUtc: json['occurredAtUtc'] == null
            ? null
            : DateTime.tryParse(json['occurredAtUtc'].toString()),
      );
}

class RewardedDeckCreditGrant {
  const RewardedDeckCreditGrant({
    required this.granted,
    required this.alreadyProcessed,
    required this.limitReached,
    required this.creditId,
    required this.allowance,
  });

  final bool granted;
  final bool alreadyProcessed;
  final bool limitReached;
  final String? creditId;
  final RecommendationAllowance? allowance;

  factory RewardedDeckCreditGrant.fromJson(Map<String, dynamic> json) =>
      RewardedDeckCreditGrant(
        granted: json['granted'] ?? false,
        alreadyProcessed: json['alreadyProcessed'] ?? false,
        limitReached: json['limitReached'] ?? false,
        creditId: json['creditId']?.toString(),
        allowance: json['allowance'] is Map<String, dynamic>
            ? RecommendationAllowance.fromJson(
                json['allowance'] as Map<String, dynamic>,
              )
            : null,
      );
}
