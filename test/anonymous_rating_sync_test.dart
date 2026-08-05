import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rapid guest ratings survive restart and drain after API recovery',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final originalBaseUrl = ServiceAgent.baseUrl;
      final originalState = ServiceAgent.state;
      final originalDebugPrint = debugPrint;
      final syncLogs = <String>[];
      MoviesState? firstRun;
      MoviesState? restarted;

      ServiceAgent.baseUrl = 'http://127.0.0.1/';
      final ratingService = _RatingServiceAgent();

      addTearDown(() async {
        firstRun?.dispose();
        restarted?.dispose();
        debugPrint = originalDebugPrint;
        ServiceAgent.baseUrl = originalBaseUrl;
        ServiceAgent.state = originalState;
      });

      debugPrint = (message, {wrapWidth}) {
        if (message != null && message.startsWith('Guest rating sync')) {
          syncLogs.add(message);
        }
      };
      ServiceAgent.state = _GuestState();

      firstRun = MoviesState(
        storage: storage,
        serviceAgent: ratingService,
      );
      await firstRun.cacheInitialization;

      await firstRun.queueAnonymousRatingSync(
        'movie-0',
        MovieRate.liked,
      );
      expect(await firstRun.retryPendingAnonymousRatingSyncs(), isFalse);

      await Future.wait([
        for (var index = 1; index < 10; index++)
          firstRun.queueAnonymousRatingSync(
            'movie-$index',
            MovieRate.liked,
          ),
      ]);

      expect(firstRun.pendingAnonymousRatingSyncCount, 10);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(ratingService.requestBodies, hasLength(1));
      expect(
        syncLogs.where((log) => log.contains('queued retry')).length,
        1,
      );

      final persistedQueue = jsonDecode(
        (await storage.read(key: 'pendingAnonymousRatingSyncs'))!,
      ) as List<dynamic>;
      expect(persistedQueue, hasLength(10));

      firstRun.dispose();
      firstRun = null;
      ratingService.acceptRatings = true;

      restarted = MoviesState(
        storage: storage,
        serviceAgent: ratingService,
      );
      await restarted.cacheInitialization;
      await restarted.setCachedPendingAnonymousRatingSyncs();

      expect(restarted.pendingAnonymousRatingSyncCount, 10);
      expect(await restarted.retryPendingAnonymousRatingSyncs(), isTrue);
      expect(restarted.pendingAnonymousRatingSyncCount, 0);
      expect(
        await storage.read(key: 'pendingAnonymousRatingSyncs'),
        isNull,
      );
      expect(
        ratingService.requestBodies
            .map((body) => body['MovieId'])
            .whereType<String>()
            .toSet(),
        hasLength(10),
      );
      expect(
        syncLogs.where((log) => log.contains('persisted 10')).length,
        1,
      );
    },
  );
}

class _GuestState {
  String userId = 'guest-rating-sync-test';
  bool isIncognitoMode = true;
  String token = 'guest-token';
  String refreshToken = 'guest-refresh-token';
}

class _RatingServiceAgent extends ServiceAgent {
  bool acceptRatings = false;
  final List<Map<String, dynamic>> requestBodies = [];

  @override
  Future<http.Response> rateMovie(
    String movieId,
    String userId,
    int movieRate,
  ) async {
    requestBodies.add({
      'MovieId': movieId,
      'UserId': userId,
      'MovieRate': movieRate,
    });

    if (!acceptRatings) {
      throw TimeoutException('simulated guest rating timeout');
    }

    return http.Response('', 200);
  }
}
