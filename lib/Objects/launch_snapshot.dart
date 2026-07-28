class OnboardingStage {
  static const none = 'None';
  static const rating = 'Rating';
  static const completed = 'Completed';
  static const skipped = 'Skipped';

  static const values = {none, rating, completed, skipped};

  static String normalize(String? value) {
    return values.contains(value) ? value! : none;
  }
}

enum LaunchDestination {
  bootstrapAnonymous,
  rateMovies,
  discover,
}

class LaunchSnapshot {
  const LaunchSnapshot({
    required this.userId,
    required this.isIncognitoMode,
    required this.hasCredentials,
    required this.onboardingStage,
    required this.ratedMoviesCount,
    required this.lastSuccessfulLibraryRefreshAt,
  });

  static const schemaVersion = 1;

  final String? userId;
  final bool isIncognitoMode;
  final bool hasCredentials;
  final String onboardingStage;
  final int? ratedMoviesCount;
  final DateTime? lastSuccessfulLibraryRefreshAt;

  factory LaunchSnapshot.fromJson(Map<String, dynamic> json) {
    final countValue = json['ratedMoviesCount'];
    final parsedCount =
        countValue is int ? countValue : int.tryParse('${countValue ?? ''}');

    return LaunchSnapshot(
      userId: _nonEmptyString(json['userId']),
      isIncognitoMode: json['isIncognitoMode'] == true,
      hasCredentials: json['hasCredentials'] == true,
      onboardingStage:
          OnboardingStage.normalize('${json['onboardingStage'] ?? ''}'),
      ratedMoviesCount:
          parsedCount == null || parsedCount < 0 ? null : parsedCount,
      lastSuccessfulLibraryRefreshAt: DateTime.tryParse(
        '${json['lastSuccessfulLibraryRefreshAt'] ?? ''}',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'userId': userId,
        'isIncognitoMode': isIncognitoMode,
        'hasCredentials': hasCredentials,
        'onboardingStage': onboardingStage,
        'ratedMoviesCount': ratedMoviesCount,
        'lastSuccessfulLibraryRefreshAt':
            lastSuccessfulLibraryRefreshAt?.toIso8601String(),
      };

  static String? _nonEmptyString(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }
}

LaunchDestination resolveLaunchDestination({
  required bool hasAuthenticatedSession,
  required bool hasAnonymousProfile,
  required String onboardingStage,
}) {
  if (hasAuthenticatedSession) {
    return LaunchDestination.discover;
  }

  if (hasAnonymousProfile) {
    return OnboardingStage.normalize(onboardingStage) == OnboardingStage.rating
        ? LaunchDestination.rateMovies
        : LaunchDestination.discover;
  }

  return LaunchDestination.bootstrapAnonymous;
}
