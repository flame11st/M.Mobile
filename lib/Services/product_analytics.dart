import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Enums/movie_rate.dart';

import 'service_agent.dart';

enum ProductAnalyticsEventName {
  appOpen('app_open'),
  onboardingStarted('onboarding_started'),
  onboardingSkipped('onboarding_skipped'),
  ratingStarted('rating_started'),
  movieRated('movie_rated'),
  rating5Complete('rating_5_complete'),
  rating10Complete('rating_10_complete'),
  discoverViewed('discover_viewed'),
  movieDnaExpanded('moviedna_expanded'),
  recommendationStarted('recommendation_started'),
  recommendationGenerated('recommendation_generated'),
  recommendationViewed('recommendation_viewed'),
  recommendationWatchlistAdded('recommendation_watchlist_added'),
  recommendationSeenAlready('recommendation_seen_already'),
  recommendationDetailsOpened('recommendation_details_opened'),
  recommendationDeckCompleted('recommendation_deck_completed'),
  watchlistAdded('watchlist_added'),
  watchlistRemoved('watchlist_removed'),
  markWatchedStarted('mark_watched_started'),
  markWatchedCompleted('mark_watched_completed'),
  movieRatingChanged('movie_rating_changed'),
  searchStarted('search_started'),
  searchSuccess('search_success'),
  searchNoResults('search_no_results'),
  whereToWatchViewed('where_to_watch_viewed'),
  whereToWatchClicked('where_to_watch_clicked'),
  personalListCreated('personal_list_created'),
  personalListItemAdded('personal_list_item_added'),
  signInStarted('sign_in_started'),
  signInCompleted('sign_in_completed'),
  premiumViewed('premium_viewed'),
  premiumStarted('premium_started'),
  premiumCompleted('premium_completed'),
  interstitialShown('interstitial_shown'),
  interstitialClosed('interstitial_closed'),
  userExitAfterAd('user_exit_after_ad');

  const ProductAnalyticsEventName(this.wireName);

  final String wireName;
}

enum ProductAnalyticsParameter {
  mediaType('media_type'),
  discoveryMode('discovery_mode'),
  resultCount('result_count'),
  sourceSurface('source_surface'),
  opinionState('opinion_state'),
  previousOpinionState('previous_opinion_state'),
  providerCategory('provider_category'),
  premiumState('premium_state'),
  latencyBucket('latency_bucket'),
  outcomeCategory('outcome_category'),
  movieId('movie_id'),
  listId('list_id'),
  recommendationSessionId('recommendation_session_id'),
  position('position'),
  ratingCount('rating_count'),
  entryPoint('entry_point'),
  authMethod('auth_method'),
  adPlacement('ad_placement'),
  platform('platform'),
  appVersion('app_version');

  const ProductAnalyticsParameter(this.wireName);

  final String wireName;
}

abstract interface class ProductAnalyticsStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SecureProductAnalyticsStorage implements ProductAnalyticsStorage {
  const SecureProductAnalyticsStorage([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

abstract interface class ProductAnalyticsTransport {
  Future<bool> send(List<Map<String, dynamic>> events);
}

class ApiProductAnalyticsTransport implements ProductAnalyticsTransport {
  ApiProductAnalyticsTransport([ServiceAgent? serviceAgent])
      : _serviceAgent = serviceAgent ?? ServiceAgent();

  final ServiceAgent _serviceAgent;

  @override
  Future<bool> send(List<Map<String, dynamic>> events) async {
    final state = ServiceAgent.state;
    final token = state?.token?.toString() ?? '';
    if (token.isEmpty) {
      return false;
    }

    final response = await _serviceAgent.ingestProductAnalytics(events);
    final delivered = response.statusCode >= 200 && response.statusCode < 300;
    if (!delivered && kDebugMode) {
      final detail = response.body.replaceAll(RegExp(r'\s+'), ' ').trim();
      final safeDetail =
          detail.length <= 240 ? detail : detail.substring(0, 240);
      debugPrint(
        'ProductAnalytics: delivery rejected with HTTP '
        '${response.statusCode}${safeDetail.isEmpty ? '' : ' ($safeDetail)'}',
      );
    }
    return delivered;
  }
}

typedef ProductAnalyticsClock = DateTime Function();
typedef ProductAnalyticsIdFactory = String Function(String prefix);

class ProductAnalytics {
  ProductAnalytics({
    ProductAnalyticsStorage? storage,
    ProductAnalyticsTransport? transport,
    ProductAnalyticsClock? clock,
    ProductAnalyticsIdFactory? idFactory,
    this.recordAppOpen = true,
    this.maxQueueSize = 250,
    this.retention = const Duration(days: 7),
  })  : _storage = storage ?? const SecureProductAnalyticsStorage(),
        _transport = transport ?? ApiProductAnalyticsTransport(),
        _clock = clock ?? DateTime.now,
        _idFactory = idFactory ?? _secureId;

  static final ProductAnalytics instance = ProductAnalytics();

  static const schemaVersion = 1;
  static const _installationKey = 'productAnalyticsInstallationV1';
  static const _queueKey = 'productAnalyticsQueueV1';
  static const _recentTransitionsKey = 'productAnalyticsTransitionsV1';
  static const _batchSize = 50;
  static const _maxRecentTransitions = 300;

  final ProductAnalyticsStorage _storage;
  final ProductAnalyticsTransport _transport;
  final ProductAnalyticsClock _clock;
  final ProductAnalyticsIdFactory _idFactory;
  final bool recordAppOpen;
  final int maxQueueSize;
  final Duration retention;

  Future<void>? _initialization;
  Future<bool>? _flushInFlight;
  final List<_QueuedAnalyticsEvent> _queue = [];
  final List<String> _recentTransitions = [];
  late String _installationId;
  late final String _sessionId = _idFactory('s');
  String? _userPseudonymousId;

  @visibleForTesting
  List<Map<String, dynamic>> get queuedEvents =>
      _queue.map((event) => event.toWireJson()).toList(growable: false);

  @visibleForTesting
  String? get userPseudonymousId => _userPseudonymousId;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    _installationId = await _readOrCreateInstallationId();
    await _restoreQueue();
    await _restoreRecentTransitions();
    _discardExpiredEvents();

    if (recordAppOpen) {
      await _enqueue(
        ProductAnalyticsEventName.appOpen,
        const {},
        transitionId: _sessionId,
      );
    }

    unawaited(flush());
  }

  Future<bool> track(
    ProductAnalyticsEventName name, {
    Map<ProductAnalyticsParameter, Object?> parameters = const {},
    String? transitionId,
  }) async {
    try {
      await initialize();
      return await _enqueue(
        name,
        parameters,
        transitionId: transitionId,
      );
    } catch (error) {
      _diagnose('queue unavailable for ${name.wireName}: $error');
      return false;
    }
  }

  Future<void> setAuthenticatedUser(String? userId) async {
    try {
      await initialize();
      final normalized = userId?.replaceAll('-', '').toLowerCase() ?? '';
      _userPseudonymousId = RegExp(r'^[a-f0-9]{32}$').hasMatch(normalized)
          ? 'u_$normalized'
          : null;
      unawaited(flush());
    } catch (error) {
      _diagnose('identity transition unavailable: $error');
    }
  }

  Future<void> clearAuthenticatedUser() async {
    await setAuthenticatedUser(null);
  }

  Future<bool> _enqueue(
    ProductAnalyticsEventName name,
    Map<ProductAnalyticsParameter, Object?> parameters, {
    String? transitionId,
  }) async {
    final encodedParameters = <String, Object?>{};
    for (final entry in parameters.entries) {
      if (!_isAllowedValue(entry.value)) {
        _diagnose('rejected ${name.wireName}: invalid categorical value');
        return false;
      }
      encodedParameters[entry.key.wireName] = entry.value;
    }

    final transitionKey = transitionId == null || transitionId.isEmpty
        ? null
        : '${name.wireName}:$transitionId';
    if (transitionKey != null && _recentTransitions.contains(transitionKey)) {
      return false;
    }

    final event = _QueuedAnalyticsEvent(
      eventId: _idFactory('e'),
      schemaVersion: schemaVersion,
      occurredAtUtc: _clock().toUtc(),
      installationId: _installationId,
      sessionId: _sessionId,
      userPseudonymousId: _userPseudonymousId,
      name: name.wireName,
      parameters: encodedParameters,
      transitionKey: transitionKey,
    );

    _queue.add(event);
    if (transitionKey != null) {
      _recentTransitions.add(transitionKey);
      if (_recentTransitions.length > _maxRecentTransitions) {
        _recentTransitions.removeRange(
          0,
          _recentTransitions.length - _maxRecentTransitions,
        );
      }
    }

    _discardExpiredEvents();
    if (_queue.length > maxQueueSize) {
      _queue.removeRange(0, _queue.length - maxQueueSize);
    }
    await _persistState();
    unawaited(flush());
    return true;
  }

  Future<bool> flush() async {
    await initialize();
    final activeFlush = _flushInFlight;
    if (activeFlush != null) {
      return activeFlush;
    }

    final future = _flushQueue();
    _flushInFlight = future;
    try {
      return await future;
    } finally {
      _flushInFlight = null;
    }
  }

  Future<bool> _flushQueue() async {
    try {
      while (_queue.isNotEmpty) {
        final batch = _queue.take(_batchSize).toList(growable: false);
        final sent = await _transport.send(
          batch.map((event) => event.toWireJson()).toList(growable: false),
        );
        if (!sent) {
          return false;
        }

        final sentIds = batch.map((event) => event.eventId).toSet();
        _queue.removeWhere((event) => sentIds.contains(event.eventId));
        await _persistState();
        _diagnose('delivered ${batch.length} event(s)');
      }
      return true;
    } catch (error) {
      _diagnose('delivery deferred: $error');
      return false;
    }
  }

  Future<String> _readOrCreateInstallationId() async {
    final stored = await _storage.read(_installationKey);
    if (stored != null && RegExp(r'^i_[a-f0-9]{32}$').hasMatch(stored)) {
      return stored;
    }

    final created = _idFactory('i');
    await _storage.write(_installationKey, created);
    return created;
  }

  Future<void> _restoreQueue() async {
    final encoded = await _storage.read(_queueKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        return;
      }
      for (final value in decoded) {
        if (value is Map) {
          final restored = _QueuedAnalyticsEvent.tryFromStorageJson(
            Map<String, dynamic>.from(value),
          );
          if (restored != null) {
            _queue.add(restored);
          }
        }
      }
    } catch (error) {
      _diagnose('ignored unreadable queue: $error');
    }
  }

  Future<void> _restoreRecentTransitions() async {
    final encoded = await _storage.read(_recentTransitionsKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is List) {
        _recentTransitions.addAll(
          decoded.whereType<String>().take(_maxRecentTransitions),
        );
      }
    } catch (error) {
      _diagnose('ignored unreadable transition history: $error');
    }
  }

  void _discardExpiredEvents() {
    final cutoff = _clock().toUtc().subtract(retention);
    _queue.removeWhere((event) => event.occurredAtUtc.isBefore(cutoff));
  }

  Future<void> _persistState() => Future.wait([
        _storage.write(
          _queueKey,
          jsonEncode(
            _queue
                .map((event) => event.toStorageJson())
                .toList(growable: false),
          ),
        ),
        _storage.write(_recentTransitionsKey, jsonEncode(_recentTransitions)),
      ]);

  static bool _isAllowedValue(Object? value) {
    if (value == null || value is bool || value is int) {
      return true;
    }
    if (value is! String || value.length > 80) {
      return false;
    }
    final normalized = value.toLowerCase();
    return !value.contains('@') &&
        !normalized.contains('bearer ') &&
        !normalized.contains('token=');
  }

  static String _secureId(String prefix) {
    final random = Random.secure();
    final value = List<int>.generate(16, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${prefix}_$value';
  }

  void _diagnose(String message) {
    if (kDebugMode) {
      debugPrint('ProductAnalytics: $message');
    }
  }
}

Future<void> trackMovieStateTransition({
  required String movieId,
  required int previousRate,
  required int nextRate,
  required String sourceSurface,
}) async {
  if (previousRate == nextRate) {
    return;
  }

  final analytics = ProductAnalytics.instance;
  final parameters = <ProductAnalyticsParameter, Object?>{
    ProductAnalyticsParameter.movieId: movieId,
    ProductAnalyticsParameter.sourceSurface: sourceSurface,
    ProductAnalyticsParameter.opinionState: _opinionValue(nextRate),
    ProductAnalyticsParameter.previousOpinionState: _opinionValue(previousRate),
  };
  if (previousRate == MovieRate.addedToWatchlist &&
      nextRate != MovieRate.addedToWatchlist) {
    await analytics.track(
      ProductAnalyticsEventName.watchlistRemoved,
      parameters: parameters,
    );
  }

  if (nextRate == MovieRate.addedToWatchlist) {
    await analytics.track(
      ProductAnalyticsEventName.watchlistAdded,
      parameters: parameters,
    );
    return;
  }

  if (MovieRate.isViewed(nextRate)) {
    await analytics.track(
      MovieRate.isViewed(previousRate)
          ? ProductAnalyticsEventName.movieRatingChanged
          : ProductAnalyticsEventName.movieRated,
      parameters: parameters,
    );
  }
}

String _opinionValue(int movieRate) => switch (movieRate) {
      MovieRate.liked => 'liked',
      MovieRate.okay => 'okay',
      MovieRate.notLiked => 'disliked',
      MovieRate.addedToWatchlist => 'watchlist',
      _ => 'not_rated',
    };

class _QueuedAnalyticsEvent {
  const _QueuedAnalyticsEvent({
    required this.eventId,
    required this.schemaVersion,
    required this.occurredAtUtc,
    required this.installationId,
    required this.sessionId,
    required this.userPseudonymousId,
    required this.name,
    required this.parameters,
    this.transitionKey,
  });

  final String eventId;
  final int schemaVersion;
  final DateTime occurredAtUtc;
  final String installationId;
  final String sessionId;
  final String? userPseudonymousId;
  final String name;
  final Map<String, Object?> parameters;
  final String? transitionKey;

  Map<String, dynamic> toWireJson() => {
        'eventId': _formatGuid(eventId.substring(2)),
        'schemaVersion': schemaVersion,
        'occurredAtUtc': occurredAtUtc.toIso8601String(),
        'installationId': installationId,
        'sessionId': sessionId,
        if (userPseudonymousId != null)
          'userPseudonymousId': userPseudonymousId,
        'name': name,
        'parameters': parameters,
      };

  Map<String, dynamic> toStorageJson() => {
        ...toWireJson(),
        'eventId': eventId.substring(2),
        if (transitionKey != null) 'transitionKey': transitionKey,
      };

  static String _formatGuid(String compact) =>
      '${compact.substring(0, 8)}-${compact.substring(8, 12)}-'
      '${compact.substring(12, 16)}-${compact.substring(16, 20)}-'
      '${compact.substring(20)}';

  static _QueuedAnalyticsEvent? tryFromStorageJson(
    Map<String, dynamic> json,
  ) {
    final eventId = json['eventId']?.toString() ?? '';
    final occurredAt =
        DateTime.tryParse(json['occurredAtUtc']?.toString() ?? '');
    final installationId = json['installationId']?.toString() ?? '';
    final sessionId = json['sessionId']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final schema = json['schemaVersion'];
    final parameters = json['parameters'];
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(eventId) ||
        occurredAt == null ||
        !RegExp(r'^i_[a-f0-9]{32}$').hasMatch(installationId) ||
        !RegExp(r'^s_[a-f0-9]{32}$').hasMatch(sessionId) ||
        name.isEmpty ||
        schema is! int ||
        parameters is! Map) {
      return null;
    }

    return _QueuedAnalyticsEvent(
      eventId: 'e_$eventId',
      schemaVersion: schema,
      occurredAtUtc: occurredAt.toUtc(),
      installationId: installationId,
      sessionId: sessionId,
      userPseudonymousId: json['userPseudonymousId']?.toString(),
      name: name,
      parameters: Map<String, Object?>.from(parameters),
      transitionKey: json['transitionKey']?.toString(),
    );
  }
}
