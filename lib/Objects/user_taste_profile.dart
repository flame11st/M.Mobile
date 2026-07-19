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
}
