import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Objects/launch_snapshot.dart';
import 'package:mmobile/Objects/user.dart';
import 'package:mmobile/Services/monetization_service.dart';
import 'package:mmobile/Services/product_analytics.dart';
import 'package:mmobile/Services/service_agent.dart';

export 'package:mmobile/Objects/launch_snapshot.dart'
    show LaunchDestination, OnboardingStage;

class UserState with ChangeNotifier {
  UserState({
    FlutterSecureStorage? storage,
    ServiceAgent? serviceAgent,
    MonetizationService? monetizationService,
  })  : storage = storage ?? const FlutterSecureStorage(),
        serviceAgent = serviceAgent ?? ServiceAgent(),
        monetization = monetizationService ?? MonetizationService() {
    initialization = setInitialData();
  }

  static const _authorizationCheckTimeout = Duration(seconds: 5);
  static const launchSnapshotKey = 'launchSnapshotV1';
  static const lifetimePremiumStoreVerifiedKey =
      'lifetimePremiumStoreVerifiedV1';
  final FlutterSecureStorage storage;
  final ServiceAgent serviceAgent;
  final MonetizationService monetization;
  late final Future<void> initialization;
  Future<void> _snapshotWrite = Future.value();

  bool isUserAuthorizedOrInIncognitoMode = false;
  bool isAppLoaded = false;
  bool isSignedInWithGoogle = false;
  String? userName = '';
  String? userId = '';
  String? token = '';
  String? refreshToken = '';
  User? user;
  bool userRequested = false;
  bool showTutorial = false;
  bool isIncognitoMode = false;
  bool premiumPurchasedIncognito = false;
  bool _lifetimePremiumStoreVerified = false;
  int _premiumSyncGeneration = 0;
  bool appReviewRequested = false;
  bool shouldRequestReview = false;
  bool onboardingStarted = false;
  bool onboardingCompleted = false;
  bool onboardingSkipped = false;
  String onboardingStage = OnboardingStage.none;
  List<String> onboardingSelectedGenres = [];
  int? cachedRatedMoviesCount;
  DateTime? lastSuccessfulLibraryRefreshAt;
  int aiRequestsCount = 2;
  final Set<String> _markWatchedHintSeen = {};
  final Set<String> _markWatchedHintChecks = {};

  /// Claims only a hint that actually becomes visible, across all row copies.
  Future<void> showMarkWatchedHintOnce(bool Function() show) async {
    await initialization;
    final profile = userId?.trim() ?? '';
    if (profile.isEmpty ||
        _markWatchedHintSeen.contains(profile) ||
        !_markWatchedHintChecks.add(profile)) {
      return;
    }
    final key = 'watchlistMarkWatchedHintV1:$profile';
    try {
      if (await storage.read(key: key) == 'true') {
        _markWatchedHintSeen.add(profile);
        return;
      }
      if (userId?.trim() != profile || !show()) return;
      _markWatchedHintSeen.add(profile);
      await storage.write(key: key, value: 'true');
    } catch (error) {
      debugPrint('Mark watched hint storage unavailable: $error');
    } finally {
      _markWatchedHintChecks.remove(profile);
    }
  }

  Future<void> setInitialData() async {
    Map<String, String> storedValues = const {};
    try {
      storedValues = await storage.readAll();
    } catch (error) {
      debugPrint('Secure startup state could not be read: $error');
    }

    final snapshot = _readLaunchSnapshot(storedValues[launchSnapshotKey]);

    appReviewRequested = storedValues['appReviewRequested'] == 'true';
    _lifetimePremiumStoreVerified =
        storedValues[lifetimePremiumStoreVerifiedKey] == 'true';
    onboardingStarted = storedValues['onboardingStarted'] == 'true';
    onboardingCompleted = storedValues['onboardingCompleted'] == 'true';
    onboardingSkipped = storedValues['onboardingSkipped'] == 'true';
    onboardingStage = OnboardingStage.normalize(
      snapshot?.onboardingStage ??
          storedValues['onboardingStage'] ??
          _stageFromLegacyFlags(),
    );
    cachedRatedMoviesCount = snapshot?.ratedMoviesCount;
    lastSuccessfulLibraryRefreshAt = snapshot?.lastSuccessfulLibraryRefreshAt;

    final storedGenres = storedValues['onboardingSelectedGenres'];
    if (storedGenres != null) {
      try {
        final genres = jsonDecode(storedGenres);
        if (genres is Iterable) {
          onboardingSelectedGenres = genres.map((genre) => '$genre').toList();
        }
      } catch (error) {
        debugPrint('Stored onboarding genres were ignored: $error');
      }
    }

    token = storedValues['token'];
    refreshToken = storedValues['refreshToken'];
    userId = storedValues['userId'] ?? snapshot?.userId;
    userName = storedValues['userName'];
    isSignedInWithGoogle = storedValues['isSignedInWithGoogle'] == 'true';

    final storedUser = storedValues['user'];
    if (storedUser != null) {
      try {
        final userJson = jsonDecode(storedUser);
        if (userJson is Map<String, dynamic>) {
          user = User.fromJson(userJson);
        }
      } catch (error) {
        debugPrint('Stored user profile was ignored: $error');
      }
    }

    ServiceAgent.state = this;

    final storedIncognitoMode = storedValues['isIncognitoMode'] == 'true' ||
        snapshot?.isIncognitoMode == true;
    if (storedIncognitoMode) {
      isIncognitoMode = true;
      premiumPurchasedIncognito =
          storedValues['premiumPurchasedIncognito'] == 'true';
      if (premiumPurchasedIncognito && !_lifetimePremiumStoreVerified) {
        // Backward compatibility for purchases made by legacy anonymous
        // builds before store verification had its own durable key.
        _lifetimePremiumStoreVerified = true;
        await storage.write(
          key: lifetimePremiumStoreVerifiedKey,
          value: 'true',
        );
      }

      if (_hasStoredCredentials()) {
        isUserAuthorizedOrInIncognitoMode = true;
      } else {
        await _clearStoredIdentity();
        isIncognitoMode = false;
      }

      isAppLoaded = true;
      final hasCachedPremium = _lifetimePremiumStoreVerified ||
          premiumPurchasedIncognito ||
          user?.premiumPurchased == true;
      if (hasCachedPremium) {
        await _synchronizeCachedEntitlement();
      } else {
        // Keep ad inventory failed closed until the anonymous profile's
        // authoritative backend entitlement has been refreshed.
        await monetization.beginEntitlementRefresh();
      }
      if (_hasStoredCredentials()) {
        unawaited(_refreshStoredUserProfile(userId!));
      }
      await _persistLaunchSnapshot();
      notifyListeners();
      return;
    }

    if (_hasStoredCredentials()) {
      isUserAuthorizedOrInIncognitoMode = true;
      unawaited(_verifyAuthorizationInBackground());
    }

    isAppLoaded = true;
    if (!isIncognitoMode && _hasStoredCredentials()) {
      await ProductAnalytics.instance.setAuthenticatedUser(userId);
    }
    await _synchronizeCachedEntitlement();
    if (_lifetimePremiumStoreVerified && _hasStoredCredentials()) {
      unawaited(_synchronizeLifetimePremiumWithBackend(userId!));
    }
    unawaited(ProductAnalytics.instance.flush());
    await _persistLaunchSnapshot();
    notifyListeners();
  }

  LaunchDestination get launchDestination => resolveLaunchDestination(
        hasAuthenticatedSession: !isIncognitoMode && _hasStoredCredentials(),
        hasAnonymousProfile: isIncognitoMode && _hasStoredCredentials(),
        onboardingStage: onboardingStage,
      );

  bool get isPremium => monetization.isPremium;

  Future<void> setUser(User user) async {
    final previousUser = this.user;
    if (previousUser?.id == user.id && previousUser?.premiumPurchased == true) {
      // A delayed or stale backend response must not revoke a lifetime grant
      // for the same identity.
      user.premiumPurchased = true;
    }
    this.user = user;
    if (user.isIncognito) {
      isIncognitoMode = true;
    }
    isUserAuthorizedOrInIncognitoMode = true;

    await monetization.synchronizeEntitlement(
      isPremium: user.premiumPurchased || _lifetimePremiumStoreVerified,
      isResolved: true,
    );
    await storage.write(key: "user", value: jsonEncode(user));
    await storage.write(
        key: 'isIncognitoMode', value: isIncognitoMode.toString());
    await _persistLaunchSnapshot();
    notifyListeners();

    if (_lifetimePremiumStoreVerified && !user.premiumPurchased) {
      unawaited(_synchronizeLifetimePremiumWithBackend('${user.id}'));
    }
  }

  Future<void> increaseAiRequestsCount() async {
    aiRequestsCount += 1;

    await storage.write(
        key: "aiRequestsCount", value: aiRequestsCount.toString());
  }

  Future<void> setPremium(bool value) async {
    final effectiveValue = value || _lifetimePremiumStoreVerified;
    await monetization.synchronizeEntitlement(
      isPremium: effectiveValue,
      isResolved: true,
    );
    if (isIncognitoMode) {
      premiumPurchasedIncognito = effectiveValue;

      await storage.write(
          key: "premiumPurchasedIncognito",
          value: premiumPurchasedIncognito.toString());
    } else {
      user?.premiumPurchased = effectiveValue;

      await storage.write(key: "user", value: jsonEncode(user));
    }

    notifyListeners();
  }

  /// Applies an authoritative non-consumable store purchase immediately.
  ///
  /// Local entitlement and ad suppression happen before backend I/O. A failed
  /// sync never exposes ads again; it is retried idempotently for the same
  /// identity and again after cold start or identity merge.
  Future<bool> activateLifetimePremiumFromStore() async {
    _lifetimePremiumStoreVerified = true;
    await storage.write(
      key: lifetimePremiumStoreVerifiedKey,
      value: 'true',
    );
    await setPremium(true);

    final currentUserId = userId?.trim() ?? '';
    if (currentUserId.isEmpty) {
      return true;
    }
    return _synchronizeLifetimePremiumWithBackend(currentUserId);
  }

  Future<void> setAppReviewRequested(bool value) async {
    appReviewRequested = value;

    await storage.write(
        key: "appReviewRequested", value: appReviewRequested.toString());
  }

  Future<void> setOnboardingCompleted(bool value) async {
    onboardingCompleted = value;
    if (value) {
      onboardingStarted = true;
      onboardingSkipped = false;
      onboardingStage = OnboardingStage.completed;
    } else if (onboardingStage == OnboardingStage.completed) {
      onboardingStage = OnboardingStage.none;
    }

    await _persistOnboardingState();
    notifyListeners();
  }

  Future<void> setOnboardingStarted(bool value) async {
    onboardingStarted = value;
    if (value && onboardingStage == OnboardingStage.none) {
      onboardingStage = OnboardingStage.rating;
    }

    await storage.write(
        key: 'onboardingStarted', value: onboardingStarted.toString());
    await storage.write(key: 'onboardingStage', value: onboardingStage);
    await _persistLaunchSnapshot();

    notifyListeners();
  }

  Future<void> setOnboardingSkipped(bool value) async {
    onboardingSkipped = value;
    if (value) {
      onboardingStarted = true;
      onboardingCompleted = false;
      onboardingStage = OnboardingStage.skipped;
    } else if (onboardingStage == OnboardingStage.skipped) {
      onboardingStage = OnboardingStage.none;
    }

    await _persistOnboardingState();
    notifyListeners();
  }

  Future<void> setOnboardingStage(String stage) async {
    onboardingStage = OnboardingStage.normalize(stage);
    onboardingStarted = stage != OnboardingStage.none;
    onboardingCompleted = stage == OnboardingStage.completed;
    onboardingSkipped = stage == OnboardingStage.skipped;

    await _persistOnboardingState();
    notifyListeners();
  }

  Future<void> _persistOnboardingState() async {
    await Future.wait([
      storage.write(key: 'onboardingStage', value: onboardingStage),
      storage.write(
          key: 'onboardingStarted', value: onboardingStarted.toString()),
      storage.write(
          key: 'onboardingCompleted', value: onboardingCompleted.toString()),
      storage.write(
          key: 'onboardingSkipped', value: onboardingSkipped.toString()),
      _persistLaunchSnapshot(),
    ]);
  }

  Future<void> setOnboardingSelectedGenres(List<String> genres) async {
    onboardingSelectedGenres = genres;

    await storage.write(
        key: 'onboardingSelectedGenres', value: jsonEncode(genres));

    notifyListeners();
  }

  Future<bool> ensureAnonymousProfile() async {
    ServiceAgent.state = this;

    if (isUserAuthorizedOrInIncognitoMode &&
        isIncognitoMode &&
        _hasStoredCredentials()) {
      return true;
    }

    final response = await serviceAgent.signInIncognito();

    if (response.statusCode != 200) {
      return false;
    }

    await processLoginResponse(response.body, false);
    isIncognitoMode = true;
    isUserAuthorizedOrInIncognitoMode = true;
    await ProductAnalytics.instance.clearAuthenticatedUser();

    await storage.write(
        key: 'isIncognitoMode', value: isIncognitoMode.toString());
    await _persistLaunchSnapshot();

    notifyListeners();

    return true;
  }

  void setAppIsLoaded(bool value) {
    isAppLoaded = value;

    notifyListeners();
  }

  Future<void> proceedIncognitoMode() async {
    isIncognitoMode = true;
    isUserAuthorizedOrInIncognitoMode = true;

    notifyListeners();

    await storage.write(
        key: 'isIncognitoMode', value: isIncognitoMode.toString());
    await _persistLaunchSnapshot();
  }

  Future<void> processLoginResponse(
      String response, bool isSignedInWithThirdPartyServices) async {
    var responseJson = json.decode(response);
    var accessToken = responseJson['access_token'];
    var refreshToken = responseJson['refresh_token'];
    var userId = responseJson['userId'];
    var userName = responseJson['username'];
    var showTutorial = false; //responseJson['showTutorial'];
    final preserveLifetimePremium =
        _lifetimePremiumStoreVerified || premiumPurchasedIncognito;

    await monetization.beginEntitlementRefresh();
    isIncognitoMode = false;
    await setInitialUserData(accessToken, refreshToken, userId, userName,
        isSignedInWithThirdPartyServices, showTutorial);
    await storage.write(
        key: 'isIncognitoMode', value: isIncognitoMode.toString());
    await ProductAnalytics.instance.setAuthenticatedUser(userId);
    await _persistLaunchSnapshot();

    try {
      final userInfoResponse = await serviceAgent.getUserInfo(userId);
      if (userInfoResponse.statusCode == 200 &&
          userInfoResponse.body.trim().isNotEmpty) {
        final userJson = json.decode(userInfoResponse.body);
        if (userJson is Map<String, dynamic>) {
          await setUser(User.fromJson(userJson));
        }
      }
    } catch (error) {
      debugPrint('Authenticated user profile refresh failed: $error');
    }

    if (preserveLifetimePremium) {
      _lifetimePremiumStoreVerified = true;
      await storage.write(
        key: lifetimePremiumStoreVerifiedKey,
        value: 'true',
      );
      await setPremium(true);
      unawaited(_synchronizeLifetimePremiumWithBackend('$userId'));
    }
  }

  logout() async {
    isUserAuthorizedOrInIncognitoMode = false;

    notifyListeners();

    userRequested = false;
    user = null;
    userId = null;

    await monetization.beginEntitlementRefresh();
    await ProductAnalytics.instance.clearAuthenticatedUser();

    await clearStorage();
  }

  clearStorage() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'userId');
    await storage.delete(key: 'userName');
    await storage.delete(key: 'isSignedInWithGoogle');
    await storage.delete(key: 'user');
    await storage.delete(key: 'isIncognitoMode');
    await storage.delete(key: 'aiRequestsCount');
    await storage.delete(key: 'onboardingStarted');
    await storage.delete(key: 'onboardingCompleted');
    await storage.delete(key: 'onboardingSkipped');
    await storage.delete(key: 'onboardingStage');
    await storage.delete(key: 'onboardingSelectedGenres');
    await _snapshotWrite;
    await storage.delete(key: launchSnapshotKey);
  }

  bool _hasStoredCredentials() {
    return token != null &&
        token!.isNotEmpty &&
        refreshToken != null &&
        refreshToken!.isNotEmpty &&
        userId != null &&
        userId!.isNotEmpty;
  }

  Future<void> _clearStoredIdentity() async {
    token = null;
    refreshToken = null;
    userId = null;
    userName = null;
    user = null;
    isSignedInWithGoogle = false;
    isUserAuthorizedOrInIncognitoMode = false;

    await monetization.beginEntitlementRefresh();

    await storage.delete(key: 'token');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'userId');
    await storage.delete(key: 'userName');
    await storage.delete(key: 'isSignedInWithGoogle');
    await storage.delete(key: 'isIncognitoMode');
    await storage.delete(key: 'user');
    await _persistLaunchSnapshot();
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    token = accessToken;
    this.refreshToken = refreshToken;

    await storage.write(key: 'token', value: token);
    await storage.write(key: 'refreshToken', value: refreshToken);
    await _persistLaunchSnapshot();
  }

  Future<void> setInitialUserData(
      String token,
      String refreshToken,
      String userId,
      String userName,
      bool isSignedInWithGoogle,
      bool showTutorial) async {
    this.token = token;
    this.refreshToken = refreshToken;
    this.userId = userId;
    this.userName = userName;
    isUserAuthorizedOrInIncognitoMode = true;
    this.isSignedInWithGoogle = isSignedInWithGoogle;
    this.showTutorial = showTutorial;

    notifyListeners();

    await storage.write(key: 'token', value: token);
    await storage.write(key: 'userId', value: userId);
    await storage.write(key: 'userName', value: userName);
    await storage.write(key: 'refreshToken', value: refreshToken);
    await storage.write(
        key: 'isSignedInWithGoogle', value: isSignedInWithGoogle.toString());
    await _persistLaunchSnapshot();
  }

  changeShowTutorialField(bool value) {
    showTutorial = value;

    notifyListeners();
  }

  Future<void> setCachedRatedMoviesCount(int value) async {
    final normalizedValue = value < 0 ? 0 : value;
    if (cachedRatedMoviesCount == normalizedValue) {
      return;
    }

    cachedRatedMoviesCount = normalizedValue;
    await _persistLaunchSnapshot();
    notifyListeners();
  }

  Future<void> markLibraryRefreshSucceeded(int ratedMoviesCount) async {
    cachedRatedMoviesCount = ratedMoviesCount < 0 ? 0 : ratedMoviesCount;
    lastSuccessfulLibraryRefreshAt = DateTime.now().toUtc();
    await _persistLaunchSnapshot();
    notifyListeners();
  }

  Future<void> _verifyAuthorizationInBackground() async {
    final requestedUserId = userId;
    try {
      final response = await serviceAgent
          .checkAuthorization()
          .timeout(_authorizationCheckTimeout);
      if (response.statusCode != 200) {
        debugPrint(
          'Stored session verification returned ${response.statusCode}; '
          'the cached session remains available until an explicit sign-in '
          'decision is required.',
        );
        return;
      }

      if (requestedUserId == null || requestedUserId.isEmpty) {
        return;
      }
      final userInfoResponse = await serviceAgent
          .getUserInfo(requestedUserId)
          .timeout(_authorizationCheckTimeout);
      if (userInfoResponse.statusCode != 200 ||
          userInfoResponse.body.trim().isEmpty ||
          userId != requestedUserId) {
        return;
      }
      final userJson = json.decode(userInfoResponse.body);
      if (userJson is Map<String, dynamic>) {
        await setUser(User.fromJson(userJson));
      }
    } catch (error) {
      debugPrint('Stored session verification deferred: $error');
    }
  }

  Future<void> _refreshStoredUserProfile(String expectedUserId) async {
    try {
      final userInfoResponse = await serviceAgent
          .getUserInfo(expectedUserId)
          .timeout(_authorizationCheckTimeout);
      if (userInfoResponse.statusCode != 200 ||
          userInfoResponse.body.trim().isEmpty ||
          userId != expectedUserId) {
        await _synchronizeCachedEntitlement();
        return;
      }
      final userJson = json.decode(userInfoResponse.body);
      if (userJson is Map<String, dynamic>) {
        await setUser(User.fromJson(userJson));
        return;
      }
    } catch (error) {
      debugPrint('Stored profile entitlement refresh deferred: $error');
    }

    await _synchronizeCachedEntitlement();
  }

  Future<void> _synchronizeCachedEntitlement() {
    final hasIdentity = _hasStoredCredentials();
    final cachedPremium = _lifetimePremiumStoreVerified ||
        user?.premiumPurchased == true ||
        (isIncognitoMode && premiumPurchasedIncognito);
    final isResolved = hasIdentity && (isIncognitoMode || user != null);
    return monetization.synchronizeEntitlement(
      isPremium: cachedPremium,
      isResolved: isResolved,
    );
  }

  Future<bool> _synchronizeLifetimePremiumWithBackend(
    String expectedUserId,
  ) async {
    final normalizedUserId = expectedUserId.trim();
    if (normalizedUserId.isEmpty || userId != normalizedUserId) {
      return false;
    }

    final generation = ++_premiumSyncGeneration;
    final synchronized = await _trySynchronizeLifetimePremium(
      normalizedUserId,
      generation,
    );
    if (!synchronized && generation == _premiumSyncGeneration) {
      unawaited(_retryLifetimePremiumSync(normalizedUserId, generation));
    }
    return synchronized;
  }

  Future<bool> _trySynchronizeLifetimePremium(
    String expectedUserId,
    int generation,
  ) async {
    if (generation != _premiumSyncGeneration || userId != expectedUserId) {
      return false;
    }
    try {
      final response = await serviceAgent
          .setUserPremiumPurchased(expectedUserId, true)
          .timeout(_authorizationCheckTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      debugPrint('Lifetime Premium backend sync deferred: $error');
      return false;
    }
  }

  Future<void> _retryLifetimePremiumSync(
    String expectedUserId,
    int generation,
  ) async {
    for (final delay in const [Duration(seconds: 2), Duration(seconds: 8)]) {
      await Future<void>.delayed(delay);
      if (generation != _premiumSyncGeneration ||
          userId != expectedUserId ||
          !_lifetimePremiumStoreVerified) {
        return;
      }
      if (await _trySynchronizeLifetimePremium(expectedUserId, generation)) {
        return;
      }
    }
  }

  LaunchSnapshot? _readLaunchSnapshot(String? encodedSnapshot) {
    if (encodedSnapshot == null || encodedSnapshot.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encodedSnapshot);
      if (decoded is Map<String, dynamic>) {
        return LaunchSnapshot.fromJson(decoded);
      }
    } catch (error) {
      debugPrint('Stored launch snapshot was ignored: $error');
    }

    return null;
  }

  Future<void> _persistLaunchSnapshot() {
    final encodedSnapshot = jsonEncode(
      LaunchSnapshot(
        userId: userId,
        isIncognitoMode: isIncognitoMode,
        hasCredentials: _hasStoredCredentials(),
        onboardingStage: onboardingStage,
        ratedMoviesCount: cachedRatedMoviesCount,
        lastSuccessfulLibraryRefreshAt: lastSuccessfulLibraryRefreshAt,
      ),
    );

    _snapshotWrite = _snapshotWrite.catchError((error) {
      debugPrint('Previous launch snapshot write failed: $error');
    }).then((_) async {
      try {
        await storage.write(key: launchSnapshotKey, value: encodedSnapshot);
      } catch (error) {
        debugPrint('Launch snapshot persistence failed: $error');
      }
    });

    return _snapshotWrite;
  }

  String _stageFromLegacyFlags() {
    if (onboardingCompleted) {
      return OnboardingStage.completed;
    }
    if (onboardingSkipped) {
      return OnboardingStage.skipped;
    }
    if (onboardingStarted) {
      return OnboardingStage.rating;
    }

    return OnboardingStage.none;
  }
}
