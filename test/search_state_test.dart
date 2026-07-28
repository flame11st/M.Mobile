import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Widgets/search_state.dart';

void main() {
  group('MovieSearchRequestGuard', () {
    test('invalidates stale request IDs', () {
      final guard = MovieSearchRequestGuard();
      final first = guard.invalidate();
      final second = guard.invalidate();

      expect(guard.isCurrent(first), isFalse);
      expect(guard.isCurrent(second), isTrue);
    });
  });

  group('MovieSearchStateController', () {
    test('rapid query changes ignore a stale response', () async {
      final firstResponse = Completer<MovieSearchTransportResponse>();
      final controller = _controller(
        fetcher: (encodedQuery, _) {
          final query = Uri.decodeQueryComponent(encodedQuery);
          if (query == 'Blade Runner') {
            return firstResponse.future;
          }
          return Future.value(_movieResponse(title: 'The Matrix'));
        },
      );
      addTearDown(controller.dispose);

      controller.onQueryChanged('Blade Runner');
      await _waitForRequestStart();
      controller.onQueryChanged('Matrix');
      await _waitForTerminalState();

      expect(controller.state.phase, MovieSearchPhase.results);
      expect(controller.state.query, 'Matrix');
      expect(controller.state.movies.single.title, 'The Matrix');

      firstResponse.complete(_movieResponse(title: 'Blade Runner'));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(controller.state.query, 'Matrix');
      expect(controller.state.movies.single.title, 'The Matrix');
    });

    test('successful 200 response reaches results', () async {
      final controller = _controller(
        fetcher: (_, __) async => _movieResponse(title: 'Arrival'),
      );
      addTearDown(controller.dispose);

      controller.onQueryChanged('Arrival');
      await _waitForTerminalState();

      expect(controller.state.phase, MovieSearchPhase.results);
      expect(controller.state.movies.single.title, 'Arrival');
      expect(controller.takePendingAnnouncement(), '1 result found');
    });

    test('empty 200 response reaches the explicit empty state', () async {
      final controller = _controller(
        fetcher: (_, __) async => const MovieSearchTransportResponse(
          statusCode: 200,
          body: '[]',
        ),
      );
      addTearDown(controller.dispose);

      controller.onQueryChanged('nonsense title');
      await _waitForTerminalState();

      expect(controller.state.phase, MovieSearchPhase.empty);
      expect(controller.state.query, 'nonsense title');
    });

    test('malformed 200 response reaches a retryable error', () async {
      final controller = _controller(
        fetcher: (_, __) async => const MovieSearchTransportResponse(
          statusCode: 200,
          body: '{"unexpected":true}',
        ),
      );
      addTearDown(controller.dispose);

      controller.onQueryChanged('Matrix');
      await _waitForTerminalState();

      expect(controller.state.phase, MovieSearchPhase.error);
      expect(controller.state.message, contains('could not read'));
    });

    for (final statusCode in [401, 500]) {
      test('$statusCode response reaches a truthful generic error', () async {
        final controller = _controller(
          fetcher: (_, __) async => MovieSearchTransportResponse(
            statusCode: statusCode,
            body: '',
          ),
        );
        addTearDown(controller.dispose);

        controller.onQueryChanged('Matrix');
        await _waitForTerminalState();

        expect(controller.state.phase, MovieSearchPhase.error);
        expect(controller.state.message, isNot(contains('localhost')));
        expect(controller.state.message, isNot(contains('API')));
      });
    }

    test('12+ second request reaches timeout before a stale response can land',
        () async {
      final response = Completer<MovieSearchTransportResponse>();
      final controller = _controller(
        fetcher: (_, __) => response.future,
        requestTimeout: const Duration(milliseconds: 20),
      );
      addTearDown(controller.dispose);

      controller.onQueryChanged('Blade Runner');
      await Future<void>.delayed(const Duration(milliseconds: 35));

      expect(controller.state.phase, MovieSearchPhase.timeout);
      expect(controller.state.query, 'Blade Runner');

      response.complete(_movieResponse(title: 'Blade Runner'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(controller.state.phase, MovieSearchPhase.timeout);
    });

    test('retry preserves the exact trimmed query and resets the request ID',
        () async {
      final queries = <String>[];
      var attempt = 0;
      final controller = _controller(
        fetcher: (encodedQuery, _) async {
          queries.add(Uri.decodeQueryComponent(encodedQuery));
          attempt += 1;
          if (attempt == 1) {
            return const MovieSearchTransportResponse(
              statusCode: 500,
              body: '',
            );
          }
          return _movieResponse(title: 'Toy Story');
        },
      );
      addTearDown(controller.dispose);

      controller.onQueryChanged('  Toy Story  ');
      await _waitForTerminalState();
      final failedRequestId = controller.state.requestId;
      expect(controller.state.phase, MovieSearchPhase.error);

      controller.retry();
      await _waitForTerminalState();

      expect(controller.state.phase, MovieSearchPhase.results);
      expect(controller.state.requestId, greaterThan(failedRequestId));
      expect(queries, ['Toy Story', 'Toy Story']);
    });

    test('tab exit invalidates an in-flight request', () async {
      final response = Completer<MovieSearchTransportResponse>();
      final controller = _controller(
        fetcher: (_, __) => response.future,
      );
      addTearDown(controller.dispose);

      controller.onQueryChanged('Matrix');
      await _waitForRequestStart();
      controller.cancelForTabExit();
      response.complete(_movieResponse(title: 'The Matrix'));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(controller.state.phase, MovieSearchPhase.loading);
      expect(controller.state.movies, isEmpty);
    });
  });
}

MovieSearchStateController _controller({
  required MovieSearchFetcher fetcher,
  Duration requestTimeout = const Duration(milliseconds: 100),
}) {
  return MovieSearchStateController(
    fetcher: fetcher,
    debounceDuration: const Duration(milliseconds: 1),
    requestTimeout: requestTimeout,
    minimumLoadingDuration: Duration.zero,
  );
}

Future<void> _waitForRequestStart() {
  return Future<void>.delayed(const Duration(milliseconds: 4));
}

Future<void> _waitForTerminalState() {
  return Future<void>.delayed(const Duration(milliseconds: 12));
}

MovieSearchTransportResponse _movieResponse({required String title}) {
  return MovieSearchTransportResponse(
    statusCode: 200,
    body: jsonEncode([
      {
        'id': title.toLowerCase().replaceAll(' ', '-'),
        'title': title,
        'tagline': null,
        'overview': 'Overview',
        'posterPath': '',
        'genres': ['Drama'],
        'releaseDate': '2020-01-01T00:00:00.000Z',
        'duration': 120,
        'likedVotes': 10,
        'unlikedVotes': 2,
        'movieRate': 0,
        'movieType': 0,
        'countries': 'United States',
        'actors': <String>[],
        'directors': <String>[],
        'seasonsCount': 0,
        'averageTimeOfEpisode': 0,
        'inProduction': false,
        'imdbRate': 8.1,
        'imdbVotes': 1000,
      }
    ]),
  );
}
