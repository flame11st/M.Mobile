class UserTasteProfile {
  final bool isReady;
  final bool isGenerated;
  final int ratingsCount;
  final List<String> favoriteGenres;
  final List<String> dislikedGenres;
  final List<String> favoriteThemes;
  final List<String> tastePillars;
  final List<String> recommendationAdvice;
  final List<String> preferredDecades;
  final List<String> favoriteDirectors;
  final List<MovieDnaInsight> insights;
  final int movieRatingsCount;
  final int tvRatingsCount;
  final int profileConfidencePercent;
  final bool isStale;
  final String? summaryText;
  final String? personalityLabel;
  final DateTime? generatedAt;

  const UserTasteProfile({
    required this.isReady,
    required this.isGenerated,
    required this.ratingsCount,
    this.favoriteGenres = const [],
    this.dislikedGenres = const [],
    this.favoriteThemes = const [],
    this.tastePillars = const [],
    this.recommendationAdvice = const [],
    this.preferredDecades = const [],
    this.favoriteDirectors = const [],
    this.insights = const [],
    this.movieRatingsCount = 0,
    this.tvRatingsCount = 0,
    this.profileConfidencePercent = 0,
    this.isStale = false,
    this.summaryText,
    this.personalityLabel,
    this.generatedAt,
  });

  factory UserTasteProfile.empty() {
    return const UserTasteProfile(
      isReady: false,
      isGenerated: false,
      ratingsCount: 0,
    );
  }

  factory UserTasteProfile.fromJson(Map<String, dynamic> json) {
    return UserTasteProfile(
      isReady: json['isReady'] ?? false,
      isGenerated: json['isGenerated'] ?? false,
      ratingsCount: json['ratingsCount'] ?? 0,
      favoriteGenres: _readStrings(json['favoriteGenres']),
      dislikedGenres: _readStrings(json['dislikedGenres']),
      favoriteThemes: _readStrings(json['favoriteThemes']),
      tastePillars: _readStrings(json['tastePillars']),
      recommendationAdvice: _readStrings(json['recommendationAdvice']),
      preferredDecades: _readStrings(json['preferredDecades']),
      favoriteDirectors: _readStrings(json['favoriteDirectors']),
      insights: _readInsights(json['insights']),
      movieRatingsCount: json['movieRatingsCount'] ?? 0,
      tvRatingsCount: json['tvRatingsCount'] ?? 0,
      profileConfidencePercent: json['profileConfidencePercent'] ?? 0,
      isStale: json['isStale'] ?? false,
      summaryText: json['summaryText'],
      personalityLabel: json['personalityLabel'],
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt']),
    );
  }

  static List<String> _readStrings(dynamic value) {
    if (value is! Iterable) {
      return const [];
    }

    return value.map((item) => '$item').toList();
  }

  static List<MovieDnaInsight> _readInsights(dynamic value) {
    if (value is! Iterable) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
            (item) => MovieDnaInsight.fromJson(Map<String, dynamic>.from(item)))
        .where((insight) => insight.key.isNotEmpty && insight.label.isNotEmpty)
        .toList();
  }
}

class MovieDnaInsight {
  final String key;
  final String label;
  final String description;
  final String category;
  final int confidencePercent;
  final int positiveEvidenceCount;
  final int counterEvidenceCount;
  final List<String> supportingTitleIds;
  final List<String> supportingTitles;

  const MovieDnaInsight({
    required this.key,
    required this.label,
    required this.description,
    required this.category,
    required this.confidencePercent,
    required this.positiveEvidenceCount,
    required this.counterEvidenceCount,
    this.supportingTitleIds = const [],
    this.supportingTitles = const [],
  });

  factory MovieDnaInsight.fromJson(Map<String, dynamic> json) {
    return MovieDnaInsight(
      key: '${json['key'] ?? ''}'.trim(),
      label: '${json['label'] ?? ''}'.trim(),
      description: '${json['description'] ?? ''}'.trim(),
      category: '${json['category'] ?? ''}'.trim(),
      confidencePercent: _readInt(json['confidencePercent']),
      positiveEvidenceCount: _readInt(json['positiveEvidenceCount']),
      counterEvidenceCount: _readInt(json['counterEvidenceCount']),
      supportingTitleIds: UserTasteProfile._readStrings(
        json['supportingTitleIds'],
      ),
      supportingTitles: UserTasteProfile._readStrings(
        json['supportingTitles'],
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? 0;
  }
}
