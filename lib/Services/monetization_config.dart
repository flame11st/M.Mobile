import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Services/remote_variables_client.dart';

enum MonetizationConfigSource { remote, freshCache, safeFallback }

@visibleForTesting
bool usesDevelopmentMonetizationDefaults({
  required bool isReleaseMode,
}) =>
    !isReleaseMode;

@immutable
class MonetizationConfig {
  const MonetizationConfig({
    required this.schemaVersion,
    required this.nativeAdsEnabled,
    required this.discoverNativeAdsEnabled,
    required this.generalListNativeAdsEnabled,
    required this.generalListNativeInterval,
    required this.generalListNativeMaximum,
    required this.myMoviesNativeAdsEnabled,
    required this.myMoviesNativeInterval,
    required this.myMoviesNativeMaximum,
    required this.interstitialAdsEnabled,
    required this.interstitialMinIntervalMinutes,
    required this.interstitialMaxPerSession,
    required this.interstitialMaxPerDay,
    required this.interstitialFirstSessionEnabled,
    required this.interstitialFirstDeckOfDayEnabled,
    required this.rewardedAdsEnabled,
    required this.recommendationAllowanceEnabled,
    required this.freeRecommendationDecksPerDay,
    required this.rewardedDeckLimitPerDay,
    required this.premiumAdsEnabled,
  });

  static const currentSchemaVersion = 1;

  /// The requested initial remote values. These are inert until a valid remote
  /// payload supplies them; a config outage uses [safeFallback] instead.
  static const rolloutDefaults = MonetizationConfig(
    schemaVersion: currentSchemaVersion,
    nativeAdsEnabled: true,
    discoverNativeAdsEnabled: true,
    generalListNativeAdsEnabled: true,
    generalListNativeInterval: 10,
    generalListNativeMaximum: 2,
    myMoviesNativeAdsEnabled: true,
    myMoviesNativeInterval: 10,
    myMoviesNativeMaximum: 2,
    interstitialAdsEnabled: true,
    interstitialMinIntervalMinutes: 10,
    interstitialMaxPerSession: 2,
    interstitialMaxPerDay: 3,
    interstitialFirstSessionEnabled: false,
    interstitialFirstDeckOfDayEnabled: false,
    rewardedAdsEnabled: true,
    recommendationAllowanceEnabled: true,
    freeRecommendationDecksPerDay: 2,
    rewardedDeckLimitPerDay: 3,
    premiumAdsEnabled: false,
  );

  /// Failure is intentionally less intrusive: no ad inventory or rewarded
  /// requirement, bounded non-zero policy values, and two usable free decks.
  static const safeFallback = MonetizationConfig(
    schemaVersion: currentSchemaVersion,
    nativeAdsEnabled: false,
    discoverNativeAdsEnabled: false,
    generalListNativeAdsEnabled: false,
    generalListNativeInterval: 10,
    generalListNativeMaximum: 0,
    myMoviesNativeAdsEnabled: false,
    myMoviesNativeInterval: 10,
    myMoviesNativeMaximum: 0,
    interstitialAdsEnabled: false,
    interstitialMinIntervalMinutes: 60,
    interstitialMaxPerSession: 0,
    interstitialMaxPerDay: 0,
    interstitialFirstSessionEnabled: false,
    interstitialFirstDeckOfDayEnabled: false,
    rewardedAdsEnabled: false,
    recommendationAllowanceEnabled: false,
    freeRecommendationDecksPerDay: 2,
    rewardedDeckLimitPerDay: 0,
    premiumAdsEnabled: false,
  );

  final int schemaVersion;
  final bool nativeAdsEnabled;
  final bool discoverNativeAdsEnabled;
  final bool generalListNativeAdsEnabled;
  final int generalListNativeInterval;
  final int generalListNativeMaximum;
  final bool myMoviesNativeAdsEnabled;
  final int myMoviesNativeInterval;
  final int myMoviesNativeMaximum;
  final bool interstitialAdsEnabled;
  final int interstitialMinIntervalMinutes;
  final int interstitialMaxPerSession;
  final int interstitialMaxPerDay;
  final bool interstitialFirstSessionEnabled;
  final bool interstitialFirstDeckOfDayEnabled;
  final bool rewardedAdsEnabled;
  final bool recommendationAllowanceEnabled;
  final int freeRecommendationDecksPerDay;
  final int rewardedDeckLimitPerDay;
  final bool premiumAdsEnabled;

  bool get discoverNativePlacementEnabled =>
      nativeAdsEnabled && discoverNativeAdsEnabled;
  bool get generalListNativePlacementEnabled =>
      nativeAdsEnabled &&
      generalListNativeAdsEnabled &&
      generalListNativeMaximum > 0;
  bool get myMoviesNativePlacementEnabled =>
      nativeAdsEnabled && myMoviesNativeAdsEnabled && myMoviesNativeMaximum > 0;
  bool get recommendationInterstitialPlacementEnabled =>
      interstitialAdsEnabled &&
      interstitialMaxPerSession > 0 &&
      interstitialMaxPerDay > 0;
  bool get extraRecommendationRewardedPlacementEnabled =>
      rewardedAdsEnabled && rewardedDeckLimitPerDay > 0;

  static MonetizationConfigParseResult parse(Object? value) {
    if (value is! Map) {
      return const MonetizationConfigParseResult.rejected(
        'payload_not_object',
      );
    }
    final values = Map<String, dynamic>.from(value);
    if (values['schemaVersion'] != currentSchemaVersion) {
      return const MonetizationConfigParseResult.rejected(
        'unsupported_schema_version',
      );
    }

    final rejected = <String>[];
    bool flag(String name, {bool fallback = false}) {
      final candidate = values[name];
      if (candidate is bool) {
        return candidate;
      }
      rejected.add(name);
      return fallback;
    }

    int boundedInt(
      String name, {
      required int minimum,
      required int maximum,
      required int fallback,
    }) {
      final candidate = values[name];
      if (candidate is int && candidate >= minimum && candidate <= maximum) {
        return candidate;
      }
      rejected.add(name);
      return fallback;
    }

    final premiumRequested = values['premiumAdsEnabled'];
    if (premiumRequested != false) {
      rejected.add('premiumAdsEnabled');
    }

    return MonetizationConfigParseResult.accepted(
      MonetizationConfig(
        schemaVersion: currentSchemaVersion,
        nativeAdsEnabled: flag('nativeAdsEnabled'),
        discoverNativeAdsEnabled: flag('discoverNativeAdsEnabled'),
        generalListNativeAdsEnabled: flag('generalListNativeAdsEnabled'),
        generalListNativeInterval: boundedInt(
          'generalListNativeInterval',
          minimum: 5,
          maximum: 50,
          fallback: safeFallback.generalListNativeInterval,
        ),
        generalListNativeMaximum: boundedInt(
          'generalListNativeMaximum',
          minimum: 0,
          maximum: 5,
          fallback: safeFallback.generalListNativeMaximum,
        ),
        myMoviesNativeAdsEnabled: flag('myMoviesNativeAdsEnabled'),
        myMoviesNativeInterval: boundedInt(
          'myMoviesNativeInterval',
          minimum: 5,
          maximum: 50,
          fallback: safeFallback.myMoviesNativeInterval,
        ),
        myMoviesNativeMaximum: boundedInt(
          'myMoviesNativeMaximum',
          minimum: 0,
          maximum: 5,
          fallback: safeFallback.myMoviesNativeMaximum,
        ),
        interstitialAdsEnabled: flag('interstitialAdsEnabled'),
        interstitialMinIntervalMinutes: boundedInt(
          'interstitialMinIntervalMinutes',
          minimum: 10,
          maximum: 1440,
          fallback: safeFallback.interstitialMinIntervalMinutes,
        ),
        interstitialMaxPerSession: boundedInt(
          'interstitialMaxPerSession',
          minimum: 0,
          maximum: 10,
          fallback: safeFallback.interstitialMaxPerSession,
        ),
        interstitialMaxPerDay: boundedInt(
          'interstitialMaxPerDay',
          minimum: 0,
          maximum: 20,
          fallback: safeFallback.interstitialMaxPerDay,
        ),
        interstitialFirstSessionEnabled:
            flag('interstitialFirstSessionEnabled'),
        interstitialFirstDeckOfDayEnabled:
            flag('interstitialFirstDeckOfDayEnabled'),
        rewardedAdsEnabled: flag('rewardedAdsEnabled'),
        recommendationAllowanceEnabled: flag('recommendationAllowanceEnabled'),
        freeRecommendationDecksPerDay: boundedInt(
          'freeRecommendationDecksPerDay',
          minimum: 1,
          maximum: 20,
          fallback: safeFallback.freeRecommendationDecksPerDay,
        ),
        rewardedDeckLimitPerDay: boundedInt(
          'rewardedDeckLimitPerDay',
          minimum: 0,
          maximum: 10,
          fallback: safeFallback.rewardedDeckLimitPerDay,
        ),
        // Lifetime Premium is an absolute product rule, not a remote switch.
        premiumAdsEnabled: false,
      ),
      rejected,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'nativeAdsEnabled': nativeAdsEnabled,
        'discoverNativeAdsEnabled': discoverNativeAdsEnabled,
        'generalListNativeAdsEnabled': generalListNativeAdsEnabled,
        'generalListNativeInterval': generalListNativeInterval,
        'generalListNativeMaximum': generalListNativeMaximum,
        'myMoviesNativeAdsEnabled': myMoviesNativeAdsEnabled,
        'myMoviesNativeInterval': myMoviesNativeInterval,
        'myMoviesNativeMaximum': myMoviesNativeMaximum,
        'interstitialAdsEnabled': interstitialAdsEnabled,
        'interstitialMinIntervalMinutes': interstitialMinIntervalMinutes,
        'interstitialMaxPerSession': interstitialMaxPerSession,
        'interstitialMaxPerDay': interstitialMaxPerDay,
        'interstitialFirstSessionEnabled': interstitialFirstSessionEnabled,
        'interstitialFirstDeckOfDayEnabled': interstitialFirstDeckOfDayEnabled,
        'rewardedAdsEnabled': rewardedAdsEnabled,
        'recommendationAllowanceEnabled': recommendationAllowanceEnabled,
        'freeRecommendationDecksPerDay': freeRecommendationDecksPerDay,
        'rewardedDeckLimitPerDay': rewardedDeckLimitPerDay,
        'premiumAdsEnabled': premiumAdsEnabled,
      };

  @override
  bool operator ==(Object other) =>
      other is MonetizationConfig &&
      jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => Object.hashAll(toJson().values);
}

@immutable
class MonetizationConfigParseResult {
  const MonetizationConfigParseResult.accepted(
    this.config,
    this.rejectedFields,
  )   : accepted = true,
        rejectionReason = null;

  const MonetizationConfigParseResult.rejected(this.rejectionReason)
      : accepted = false,
        config = MonetizationConfig.safeFallback,
        rejectedFields = const [];

  final bool accepted;
  final MonetizationConfig config;
  final List<String> rejectedFields;
  final String? rejectionReason;
  bool get usedFieldFallback => rejectedFields.isNotEmpty;
}

abstract interface class MonetizationConfigTransport {
  Future<Object?> fetch();
}

class RemoteVariablesMonetizationConfigTransport
    implements MonetizationConfigTransport {
  RemoteVariablesMonetizationConfigTransport({
    RemoteVariablesClient? remoteVariablesClient,
    bool? isReleaseMode,
  })  : _remoteVariablesClient =
            remoteVariablesClient ?? RemoteVariablesClient(),
        _useDevelopmentDefaults = usesDevelopmentMonetizationDefaults(
          isReleaseMode: isReleaseMode ?? kReleaseMode,
        );

  final RemoteVariablesClient _remoteVariablesClient;
  final bool _useDevelopmentDefaults;

  @override
  Future<Object?> fetch() async {
    if (_useDevelopmentDefaults) {
      debugPrint(
        'MonetizationConfig: using development rollout policy',
      );
      return MonetizationConfig.rolloutDefaults.toJson();
    }
    final variables = await _remoteVariablesClient.fetch();
    return variables['monetization'];
  }
}

abstract interface class MonetizationConfigCache {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureMonetizationConfigCache implements MonetizationConfigCache {
  const SecureMonetizationConfigCache([
    this._storage = const FlutterSecureStorage(),
  ]);

  static const storageKey = 'monetizationConfigV1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: storageKey);

  @override
  Future<void> write(String value) =>
      _storage.write(key: storageKey, value: value);
}

typedef MonetizationConfigClock = DateTime Function();

class MonetizationConfigService with ChangeNotifier {
  MonetizationConfigService({
    MonetizationConfigTransport? transport,
    MonetizationConfigCache? cache,
    MonetizationConfigClock? clock,
    this.freshness = const Duration(hours: 6),
  })  : _transport = transport ?? RemoteVariablesMonetizationConfigTransport(),
        _cache = cache ?? const SecureMonetizationConfigCache(),
        _clock = clock ?? DateTime.now;

  final MonetizationConfigTransport _transport;
  final MonetizationConfigCache _cache;
  final MonetizationConfigClock _clock;
  final Duration freshness;

  MonetizationConfig _current = MonetizationConfig.safeFallback;
  MonetizationConfigSource _source = MonetizationConfigSource.safeFallback;
  bool _isInitialized = false;
  bool _usedFallback = true;
  Future<void>? _initialization;

  MonetizationConfig get current => _current;
  MonetizationConfigSource get source => _source;
  bool get isInitialized => _isInitialized;
  bool get usedFallback => _usedFallback;

  Future<void> initialize() {
    final active = _initialization;
    if (active != null) {
      return active;
    }
    if (_isInitialized) {
      return Future.value();
    }

    final initialization = _load();
    _initialization = initialization;
    return initialization.whenComplete(() {
      _initialization = null;
      _isInitialized = true;
    });
  }

  Future<void> _load() async {
    var hasFreshCache = false;
    try {
      final cached = await _cache.read();
      if (cached != null && cached.isNotEmpty) {
        final decoded = jsonDecode(cached);
        if (decoded is Map) {
          final wrapper = Map<String, dynamic>.from(decoded);
          final cachedAt =
              DateTime.tryParse('${wrapper['cachedAtUtc']}')?.toUtc();
          final parsed = MonetizationConfig.parse(wrapper['config']);
          final age =
              cachedAt == null ? null : _clock().toUtc().difference(cachedAt);
          hasFreshCache = parsed.accepted &&
              age != null &&
              !age.isNegative &&
              age <= freshness;
          if (hasFreshCache) {
            _apply(
              parsed.config,
              MonetizationConfigSource.freshCache,
              parsed.usedFieldFallback,
            );
          }
        }
      }
    } catch (_) {
      hasFreshCache = false;
    }

    try {
      final parsed = MonetizationConfig.parse(await _transport.fetch());
      if (!parsed.accepted) {
        throw FormatException(
          parsed.rejectionReason ?? 'invalid_monetization_config',
        );
      }
      _apply(
        parsed.config,
        MonetizationConfigSource.remote,
        parsed.usedFieldFallback,
      );
      await _cache.write(jsonEncode({
        'cachedAtUtc': _clock().toUtc().toIso8601String(),
        'config': parsed.config.toJson(),
      }));
    } catch (_) {
      if (!hasFreshCache) {
        _apply(
          MonetizationConfig.safeFallback,
          MonetizationConfigSource.safeFallback,
          true,
        );
      }
    }
  }

  void _apply(
    MonetizationConfig config,
    MonetizationConfigSource source,
    bool usedFallback,
  ) {
    final changed = _current != config ||
        _source != source ||
        _usedFallback != usedFallback;
    _current = config;
    _source = source;
    _usedFallback = usedFallback;
    debugPrint(
      'MonetizationConfig: source=${source.name} '
      'schemaVersion=${config.schemaVersion} fallback=$usedFallback',
    );
    if (changed) {
      notifyListeners();
    }
  }
}
