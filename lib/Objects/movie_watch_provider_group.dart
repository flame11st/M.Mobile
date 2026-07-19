class MovieWatchProviderGroup {
  final String movieId;
  final String country;
  final String? source;
  final String? sourceLink;
  final List<MovieWatchProvider> stream;
  final List<MovieWatchProvider> rent;
  final List<MovieWatchProvider> buy;

  const MovieWatchProviderGroup({
    required this.movieId,
    required this.country,
    this.source,
    this.sourceLink,
    required this.stream,
    required this.rent,
    required this.buy,
  });

  factory MovieWatchProviderGroup.empty(String movieId, String country) {
    return MovieWatchProviderGroup(
      movieId: movieId,
      country: country,
      stream: const [],
      rent: const [],
      buy: const [],
    );
  }

  factory MovieWatchProviderGroup.fromJson(Map<String, dynamic> json) {
    return MovieWatchProviderGroup(
      movieId: json['movieId'],
      country: json['country'] ?? 'US',
      source: json['source'],
      sourceLink: json['sourceLink'],
      stream: _providersFromJson(json['stream']),
      rent: _providersFromJson(json['rent']),
      buy: _providersFromJson(json['buy']),
    );
  }

  static List<MovieWatchProvider> _providersFromJson(dynamic json) {
    if (json is! Iterable) {
      return const [];
    }

    return json
        .map<MovieWatchProvider>((model) => MovieWatchProvider.fromJson(model))
        .toList();
  }
}

class MovieWatchProvider {
  final int providerId;
  final String providerName;
  final String? logoPath;
  final int displayPriority;

  const MovieWatchProvider({
    required this.providerId,
    required this.providerName,
    this.logoPath,
    required this.displayPriority,
  });

  factory MovieWatchProvider.fromJson(Map<String, dynamic> json) {
    return MovieWatchProvider(
      providerId: json['providerId'],
      providerName: json['providerName'],
      logoPath: json['logoPath'],
      displayPriority: json['displayPriority'] ?? 0,
    );
  }
}
