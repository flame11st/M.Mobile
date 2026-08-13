import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';

enum CuratedMovieListPurpose {
  popularMovies,
  popularTv,
  topRatedMovies,
  topRatedTv,
  teamMovies,
  teamTv,
}

class MovieListCurator {
  static const tmdbPopularFreshnessWindow = Duration(days: 2);

  static MoviesList? listForPurpose(
    List<MoviesList> lists,
    CuratedMovieListPurpose purpose,
  ) {
    if (purpose != CuratedMovieListPurpose.popularMovies &&
        purpose != CuratedMovieListPurpose.popularTv) {
      final matchedLists = lists
          .where((list) => _matchesPurpose(list, purpose))
          .toList()
        ..sort(_compareSourcePriority);
      return matchedLists.isEmpty ? null : matchedLists.first;
    }

    final metadataMatches = lists
        .where((list) => _matchesTmdbSourceMetadata(list, purpose))
        .toList()
      ..sort(_compareExactSource);
    if (metadataMatches.isNotEmpty) {
      return metadataMatches.first;
    }

    final canonicalNameMatches = lists
        .where((list) => _matchesCanonicalTmdbName(list, purpose))
        .toList()
      ..sort(_compareExactSource);
    return canonicalNameMatches.isEmpty ? null : canonicalNameMatches.first;
  }

  static bool isStalePopularSource(
    MoviesList list, {
    DateTime? now,
  }) {
    final updatedAt = list.sourceUpdatedAt;
    if (updatedAt == null) {
      return false;
    }

    final age = (now ?? DateTime.now()).toUtc().difference(updatedAt.toUtc());
    return age > tmdbPopularFreshnessWindow;
  }

  static List<Movie> moviesFromListForPurpose(
    MoviesList list,
    CuratedMovieListPurpose purpose, {
    int limit = 100,
  }) {
    final seenIds = <String>{};
    return list.listMovies
        .where((movie) => _matchesMovieType(movie, purpose))
        .where((movie) => seenIds.add(movie.id))
        .take(limit)
        .toList();
  }

  static List<Movie> moviesForPurpose(
    List<MoviesList> lists,
    CuratedMovieListPurpose purpose, {
    int limit = 100,
  }) {
    if (purpose == CuratedMovieListPurpose.popularMovies ||
        purpose == CuratedMovieListPurpose.popularTv) {
      final exactList = listForPurpose(lists, purpose);
      if (exactList == null || isStalePopularSource(exactList)) {
        return const [];
      }

      return moviesFromListForPurpose(
        exactList,
        purpose,
        limit: limit,
      );
    }

    final matchedLists = lists
        .where((list) => _matchesPurpose(list, purpose))
        .toList()
      ..sort(_compareSourcePriority);
    final seenIds = <String>{};

    return matchedLists
        .expand((list) => list.listMovies)
        .where((movie) => _matchesMovieType(movie, purpose))
        .where(isTrustedBrowseItem)
        .where((movie) => seenIds.add(movie.id))
        .take(limit)
        .toList();
  }

  static List<Movie> trustedFallbackByType(
    List<MoviesList> lists,
    MovieType type, {
    int limit = 100,
  }) {
    final seenIds = <String>{};

    return lists
        .expand((list) => list.listMovies)
        .where((movie) => movie.movieType == type)
        .where(isTrustedBrowseItem)
        .where((movie) => seenIds.add(movie.id))
        .take(limit)
        .toList();
  }

  static bool isTrustedBrowseItem(Movie movie) {
    final now = DateTime.now();
    final endOfToday = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
      999,
    );
    final hasUsefulTitle = movie.title.trim().isNotEmpty;
    final title = movie.title.toLowerCase();
    final looksLikeEpisodeBundle = movie.movieType == MovieType.movie &&
        RegExp(r'\b(season|episode|episodes)\b').hasMatch(title);
    final hasReleaseDate = movie.releaseDate.year > 1;
    final hasReleased =
        hasReleaseDate && !movie.releaseDate.isAfter(endOfToday);
    final hasPoster = movie.posterPath.trim().isNotEmpty;
    final hasRuntime = movie.movieType == MovieType.tv || movie.duration >= 70;
    final hasAudienceSignal =
        movie.imdbVotes >= 1000 || movie.allVotes >= 10 || movie.rating >= 60;

    return hasUsefulTitle &&
        !looksLikeEpisodeBundle &&
        hasReleaseDate &&
        hasReleased &&
        hasPoster &&
        hasRuntime &&
        hasAudienceSignal;
  }

  static bool isTrustedStarterItem(Movie movie) {
    final hasOverview = movie.overview.trim().isNotEmpty;

    return isTrustedBrowseItem(movie) && hasOverview;
  }

  static String sourceLabelForMovie(
    Movie movie,
    List<MoviesList> lists,
  ) {
    final sortedLists = lists.toList()..sort(_compareSourcePriority);

    for (final list in sortedLists) {
      if (!list.listMovies.any((listMovie) => listMovie.id == movie.id)) {
        continue;
      }

      final name = _normalizedName(list.name);
      final isTv = movie.movieType == MovieType.tv;

      if (name.contains('team choice')) {
        return 'MovieDiary team pick';
      }

      if (name.contains('top rated')) {
        return isTv ? 'IMDb top-rated TV' : 'IMDb top-rated movie';
      }

      if (name.contains('popular')) {
        if (name.contains('tmdb')) {
          return isTv ? 'TMDb popular TV' : 'TMDb popular movie';
        }

        return isTv ? 'Popular TV pick' : 'Popular movie pick';
      }
    }

    return movie.movieType == MovieType.tv ? 'TV pick' : 'Movie pick';
  }

  static String sourceNoteForPurpose(CuratedMovieListPurpose purpose) {
    switch (purpose) {
      case CuratedMovieListPurpose.popularMovies:
        return 'Popular with MovieDiary members · released titles';
      case CuratedMovieListPurpose.popularTv:
        return 'Popular with MovieDiary members · released titles';
      case CuratedMovieListPurpose.topRatedMovies:
        return 'IMDb top-rated · high vote count';
      case CuratedMovieListPurpose.topRatedTv:
        return 'IMDb top-rated TV · high vote count';
      case CuratedMovieListPurpose.teamMovies:
        return 'Curated by MovieDiary';
      case CuratedMovieListPurpose.teamTv:
        return 'Curated by MovieDiary';
    }
  }

  static bool _matchesPurpose(
    MoviesList list,
    CuratedMovieListPurpose purpose,
  ) {
    final name = _normalizedName(list.name);
    final hasPopular = name.contains('popular');
    final hasTopRated = name.contains('top rated');
    final hasTeamChoice = name.contains('team choice');
    final hasTv = name.contains('tv') || name.contains('series');
    final hasMovie = name.contains('movie');

    switch (purpose) {
      case CuratedMovieListPurpose.popularMovies:
        return hasPopular && hasMovie && !hasTv;
      case CuratedMovieListPurpose.popularTv:
        return hasPopular && hasTv;
      case CuratedMovieListPurpose.topRatedMovies:
        return hasTopRated && hasMovie && !hasTv;
      case CuratedMovieListPurpose.topRatedTv:
        return hasTopRated && hasTv;
      case CuratedMovieListPurpose.teamMovies:
        return hasTeamChoice && hasMovie && !hasTv;
      case CuratedMovieListPurpose.teamTv:
        return hasTeamChoice && hasTv;
    }
  }

  static bool _matchesMovieType(
    Movie movie,
    CuratedMovieListPurpose purpose,
  ) {
    switch (purpose) {
      case CuratedMovieListPurpose.popularMovies:
      case CuratedMovieListPurpose.topRatedMovies:
      case CuratedMovieListPurpose.teamMovies:
        return movie.movieType == MovieType.movie;
      case CuratedMovieListPurpose.popularTv:
      case CuratedMovieListPurpose.topRatedTv:
      case CuratedMovieListPurpose.teamTv:
        return movie.movieType == MovieType.tv;
    }
  }

  static int _compareSourcePriority(MoviesList a, MoviesList b) {
    final sourceCompare = _sourcePriority(a.name).compareTo(
      _sourcePriority(b.name),
    );

    if (sourceCompare != 0) {
      return sourceCompare;
    }

    return a.order.compareTo(b.order);
  }

  static int _compareExactSource(MoviesList a, MoviesList b) {
    final aUpdated = a.sourceUpdatedAt?.toUtc();
    final bUpdated = b.sourceUpdatedAt?.toUtc();
    if (aUpdated != null && bUpdated != null) {
      final updatedCompare = bUpdated.compareTo(aUpdated);
      if (updatedCompare != 0) {
        return updatedCompare;
      }
    } else if (aUpdated != null) {
      return -1;
    } else if (bUpdated != null) {
      return 1;
    }

    return a.order.compareTo(b.order);
  }

  static bool _matchesTmdbSourceMetadata(
    MoviesList list,
    CuratedMovieListPurpose purpose,
  ) {
    final sourceKey = _normalizedSourceKey(list.sourceKey);
    if (sourceKey.isEmpty) {
      return false;
    }

    final isTmdb = sourceKey.contains('tmdb');
    final isPopular = sourceKey.contains('popular');
    final isTv = sourceKey.contains('tv') || sourceKey.contains('series');
    final isMovie = sourceKey.contains('movie');
    if (!isTmdb || !isPopular) {
      return false;
    }

    return switch (purpose) {
      CuratedMovieListPurpose.popularMovies => isMovie && !isTv,
      CuratedMovieListPurpose.popularTv => isTv,
      _ => false,
    };
  }

  static bool _matchesCanonicalTmdbName(
    MoviesList list,
    CuratedMovieListPurpose purpose,
  ) {
    final name = _normalizedName(list.name);
    return switch (purpose) {
      CuratedMovieListPurpose.popularMovies => name == 'popular movies tmdb',
      CuratedMovieListPurpose.popularTv =>
        name == 'popular tv series tmdb' || name == 'popular tv tmdb',
      _ => false,
    };
  }

  static int _sourcePriority(String name) {
    final normalized = _normalizedName(name);

    if (normalized.contains('team choice')) {
      return 0;
    }

    if (normalized.contains('moviediary')) {
      return 1;
    }

    if (normalized.contains('imdb')) {
      return 2;
    }

    if (normalized.contains('tmdb')) {
      return 3;
    }

    return 4;
  }

  static String _normalizedName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[\(\)\[\]\-_/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizedSourceKey(String? sourceKey) {
    return (sourceKey ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
