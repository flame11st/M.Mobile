import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mmobile/Objects/movie.dart';

enum MovieSearchPhase {
  landing,
  debouncing,
  loading,
  results,
  empty,
  timeout,
  error,
}

@immutable
class MovieSearchState {
  final MovieSearchPhase phase;
  final String query;
  final int requestId;
  final List<Movie> movies;
  final String? message;

  const MovieSearchState({
    required this.phase,
    required this.query,
    required this.requestId,
    this.movies = const [],
    this.message,
  });

  const MovieSearchState.landing()
      : phase = MovieSearchPhase.landing,
        query = '',
        requestId = 0,
        movies = const [],
        message = null;
}

@immutable
class MovieSearchTransportResponse {
  final int statusCode;
  final String body;

  const MovieSearchTransportResponse({
    required this.statusCode,
    required this.body,
  });
}

typedef MovieSearchFetcher = Future<MovieSearchTransportResponse> Function(
  String encodedQuery,
  bool isAdvanced,
);

class MovieSearchRequestGuard {
  int _requestId = 0;

  int invalidate() => ++_requestId;

  bool isCurrent(int requestId) => requestId == _requestId;

  int get currentRequestId => _requestId;
}

class MovieSearchStateController extends ChangeNotifier {
  final MovieSearchFetcher fetcher;
  final Duration debounceDuration;
  final Duration requestTimeout;
  final Duration minimumLoadingDuration;
  final bool isAdvanced;
  final MovieSearchRequestGuard requestGuard;

  MovieSearchState _state = const MovieSearchState.landing();
  Timer? _debounceTimer;
  String? _pendingAnnouncement;
  bool _disposed = false;

  MovieSearchStateController({
    required this.fetcher,
    this.debounceDuration = const Duration(milliseconds: 450),
    this.requestTimeout = const Duration(seconds: 12),
    this.minimumLoadingDuration = const Duration(milliseconds: 600),
    this.isAdvanced = false,
    MovieSearchRequestGuard? requestGuard,
  }) : requestGuard = requestGuard ?? MovieSearchRequestGuard();

  MovieSearchState get state => _state;

  void onQueryChanged(String value) {
    final trimmedQuery = value.trim();
    _debounceTimer?.cancel();
    final requestId = requestGuard.invalidate();

    if (trimmedQuery.isEmpty) {
      _setState(
        MovieSearchState(
          phase: MovieSearchPhase.landing,
          query: '',
          requestId: requestId,
        ),
      );
      return;
    }

    _setState(
      MovieSearchState(
        phase: MovieSearchPhase.debouncing,
        query: trimmedQuery,
        requestId: requestId,
      ),
    );

    _debounceTimer = Timer(
      debounceDuration,
      () => unawaited(_runSearch(trimmedQuery, requestId)),
    );
  }

  void clear() {
    _debounceTimer?.cancel();
    final requestId = requestGuard.invalidate();
    _setState(
      MovieSearchState(
        phase: MovieSearchPhase.landing,
        query: '',
        requestId: requestId,
      ),
    );
  }

  void retry() {
    final trimmedQuery = _state.query.trim();
    if (trimmedQuery.isEmpty) {
      clear();
      return;
    }

    _debounceTimer?.cancel();
    final requestId = requestGuard.invalidate();
    unawaited(_runSearch(trimmedQuery, requestId));
  }

  void cancelForTabExit() {
    _debounceTimer?.cancel();
    requestGuard.invalidate();
  }

  String? takePendingAnnouncement() {
    final announcement = _pendingAnnouncement;
    _pendingAnnouncement = null;
    return announcement;
  }

  Future<void> _runSearch(String query, int requestId) async {
    if (!requestGuard.isCurrent(requestId) || _disposed) {
      return;
    }

    _setState(
      MovieSearchState(
        phase: MovieSearchPhase.loading,
        query: query,
        requestId: requestId,
      ),
      announcement: 'Searching for $query',
    );

    final stopwatch = Stopwatch()..start();
    MovieSearchTransportResponse response;

    try {
      response = await fetcher(
        Uri.encodeQueryComponent(query),
        isAdvanced,
      ).timeout(requestTimeout);
    } on TimeoutException {
      if (!_isCurrent(requestId, query)) {
        return;
      }
      _setState(
        MovieSearchState(
          phase: MovieSearchPhase.timeout,
          query: query,
          requestId: requestId,
          message: 'Check your connection and try again.',
        ),
        announcement: 'Search is taking too long',
      );
      return;
    } catch (_) {
      if (!_isCurrent(requestId, query)) {
        return;
      }
      await _waitForMinimumLoading(stopwatch, requestId, query);
      if (!_isCurrent(requestId, query)) {
        return;
      }
      _setState(
        MovieSearchState(
          phase: MovieSearchPhase.error,
          query: query,
          requestId: requestId,
          message: 'Check your connection and try again.',
        ),
        announcement: 'Search unavailable',
      );
      return;
    }

    if (!_isCurrent(requestId, query)) {
      return;
    }

    if (response.statusCode != 200) {
      await _waitForMinimumLoading(stopwatch, requestId, query);
      if (!_isCurrent(requestId, query)) {
        return;
      }
      _setState(
        MovieSearchState(
          phase: MovieSearchPhase.error,
          query: query,
          requestId: requestId,
          message: 'Check your connection and try again.',
        ),
        announcement: 'Search unavailable',
      );
      return;
    }

    List<Movie> movies;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Iterable) {
        throw const FormatException('Search response is not a list.');
      }
      movies = decoded
          .map(
            (item) => Movie.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      await _waitForMinimumLoading(stopwatch, requestId, query);
      if (!_isCurrent(requestId, query)) {
        return;
      }
      _setState(
        MovieSearchState(
          phase: MovieSearchPhase.error,
          query: query,
          requestId: requestId,
          message: 'MovieDiary could not read these results. Try again.',
        ),
        announcement: 'Search unavailable',
      );
      return;
    }

    await _waitForMinimumLoading(stopwatch, requestId, query);
    if (!_isCurrent(requestId, query)) {
      return;
    }

    if (movies.isEmpty) {
      _setState(
        MovieSearchState(
          phase: MovieSearchPhase.empty,
          query: query,
          requestId: requestId,
        ),
        announcement: 'No titles found',
      );
      return;
    }

    _setState(
      MovieSearchState(
        phase: MovieSearchPhase.results,
        query: query,
        requestId: requestId,
        movies: movies,
      ),
      announcement:
          '${movies.length} result${movies.length == 1 ? '' : 's'} found',
    );
  }

  Future<void> _waitForMinimumLoading(
    Stopwatch stopwatch,
    int requestId,
    String query,
  ) async {
    final remaining = minimumLoadingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!_isCurrent(requestId, query)) {
      return;
    }
  }

  bool _isCurrent(int requestId, String query) {
    return !_disposed &&
        requestGuard.isCurrent(requestId) &&
        _state.query == query;
  }

  void _setState(
    MovieSearchState nextState, {
    String? announcement,
  }) {
    if (_disposed) {
      return;
    }
    _state = nextState;
    _pendingAnnouncement = announcement;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    requestGuard.invalidate();
    super.dispose();
  }
}
