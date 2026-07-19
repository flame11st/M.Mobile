import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Objects/user.dart';
import 'package:mmobile/Services/service_agent.dart';

class OnboardingStage {
  static const none = 'None';
  static const rating = 'Rating';
  static const completed = 'Completed';
  static const skipped = 'Skipped';
}

class UserState with ChangeNotifier {
  UserState() {
    setInitialData();
  }

  static const _authorizationCheckTimeout = Duration(seconds: 5);
  final storage = const FlutterSecureStorage();
  final serviceAgent = ServiceAgent();

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
  bool appReviewRequested = false;
  bool shouldRequestReview = false;
  bool onboardingStarted = false;
  bool onboardingCompleted = false;
  bool onboardingSkipped = false;
  String onboardingStage = OnboardingStage.none;
  List<String> onboardingSelectedGenres = [];
  int aiRequestsCount = 2;

  void setInitialData() async {
    String? storedToken;
    String? storedRefreshToken;
    String? storedUserId;
    String? storedUserName;
    String? storedSignedInWithGoogle;
    String? storedUser;
    String? storedIsIncognitoMode;
    String? storedPremiumPurchasedIncognito;
    String? storedAppReviewRequested;
    String? storedOnboardingStarted;
    String? storedOnboardingCompleted;
    String? storedOnboardingSkipped;
    String? storedOnboardingStage;
    String? storedOnboardingSelectedGenres;

    try {
      storedToken = await storage.read(key: 'token');
      storedRefreshToken = await storage.read(key: 'refreshToken');
      storedUserId = await storage.read(key: 'userId');
      storedUserName = await storage.read(key: 'userName');
      storedSignedInWithGoogle =
          await storage.read(key: 'isSignedInWithGoogle');
      storedIsIncognitoMode = await storage.read(key: 'isIncognitoMode');
      storedPremiumPurchasedIncognito =
          await storage.read(key: 'premiumPurchasedIncognito');
      storedAppReviewRequested = await storage.read(key: "appReviewRequested");
      storedOnboardingStarted = await storage.read(key: 'onboardingStarted');
      storedOnboardingCompleted =
          await storage.read(key: 'onboardingCompleted');
      storedOnboardingSkipped = await storage.read(key: 'onboardingSkipped');
      storedOnboardingStage = await storage.read(key: 'onboardingStage');
      storedOnboardingSelectedGenres =
          await storage.read(key: 'onboardingSelectedGenres');
      storedUser = await storage.read(key: 'user');
    } catch (on) {
      await clearStorage();
    }

    appReviewRequested = storedAppReviewRequested == "true";
    onboardingStarted = storedOnboardingStarted == "true";
    onboardingCompleted = storedOnboardingCompleted == "true";
    onboardingSkipped = storedOnboardingSkipped == "true";
    onboardingStage = storedOnboardingStage ?? _stageFromLegacyFlags();
    if (storedOnboardingSelectedGenres != null) {
      final genres = jsonDecode(storedOnboardingSelectedGenres);
      if (genres is Iterable) {
        onboardingSelectedGenres = genres.map((genre) => '$genre').toList();
      }
    }

    token = storedToken;
    refreshToken = storedRefreshToken;
    userId = storedUserId;
    userName = storedUserName;
    isSignedInWithGoogle = storedSignedInWithGoogle == "true";

    if (storedUser != null) {
      final userJson = jsonDecode(storedUser);
      user = User.fromJson(userJson);
    }

    ServiceAgent.state = this;

    if (storedIsIncognitoMode == "true") {
      isIncognitoMode = true;
      premiumPurchasedIncognito = storedPremiumPurchasedIncognito == "true";

      if (_hasStoredCredentials()) {
        isUserAuthorizedOrInIncognitoMode = true;
      } else {
        await _clearStoredIdentity();
        isIncognitoMode = false;
      }

      isAppLoaded = true;
      notifyListeners();
      return;
    }

    if (_hasStoredCredentials()) {
      try {
        var authorizationResponse = await serviceAgent
            .checkAuthorization()
            .timeout(_authorizationCheckTimeout);
        if (authorizationResponse.statusCode == 200) {
          isUserAuthorizedOrInIncognitoMode = true;
        }
      } catch (error) {
        debugPrint('Authorization check skipped during startup: $error');
      }
    }

    isAppLoaded = true;

    notifyListeners();
  }

  get isPremium {
    var result = user != null
        ? user?.premiumPurchased != null && user?.premiumPurchased == true
        : premiumPurchasedIncognito;

    return result;
  }

  Future<void> setUser(User user) async {
    this.user = user;
    if (user.isIncognito) {
      isIncognitoMode = true;
    }
    isUserAuthorizedOrInIncognitoMode = true;

    await storage.write(key: "user", value: jsonEncode(user));
    await storage.write(
        key: 'isIncognitoMode', value: isIncognitoMode.toString());
    notifyListeners();
  }

  Future<void> increaseAiRequestsCount() async {
    aiRequestsCount += 1;

    await storage.write(
        key: "aiRequestsCount", value: aiRequestsCount.toString());
  }

  Future<void> setPremium(bool value) async {
    if (isIncognitoMode) {
      premiumPurchasedIncognito = true;

      await storage.write(
          key: "premiumPurchasedIncognito",
          value: premiumPurchasedIncognito.toString());
    } else {
      user?.premiumPurchased = value;

      await storage.write(key: "user", value: jsonEncode(user));
    }

    notifyListeners();
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

    notifyListeners();
    _persistOnboardingState();
  }

  Future<void> setOnboardingStarted(bool value) async {
    onboardingStarted = value;
    if (value && onboardingStage == OnboardingStage.none) {
      onboardingStage = OnboardingStage.rating;
    }

    await storage.write(
        key: 'onboardingStarted', value: onboardingStarted.toString());
    await storage.write(key: 'onboardingStage', value: onboardingStage);

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

    notifyListeners();
    _persistOnboardingState();
  }

  Future<void> setOnboardingStage(String stage) async {
    onboardingStage = stage;
    onboardingStarted = stage != OnboardingStage.none;
    onboardingCompleted = stage == OnboardingStage.completed;
    onboardingSkipped = stage == OnboardingStage.skipped;

    notifyListeners();
    _persistOnboardingState();
  }

  void _persistOnboardingState() {
    unawaited(Future.wait([
      storage.write(key: 'onboardingStage', value: onboardingStage),
      storage.write(
          key: 'onboardingStarted', value: onboardingStarted.toString()),
      storage.write(
          key: 'onboardingCompleted', value: onboardingCompleted.toString()),
      storage.write(
          key: 'onboardingSkipped', value: onboardingSkipped.toString()),
    ]).catchError((error) {
      debugPrint('Onboarding state persistence failed: $error');
      return <void>[];
    }));
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

    await storage.write(
        key: 'isIncognitoMode', value: isIncognitoMode.toString());

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
  }

  Future<void> processLoginResponse(
      String response, bool isSignedInWithThirdPartyServices) async {
    var responseJson = json.decode(response);
    var accessToken = responseJson['access_token'];
    var refreshToken = responseJson['refresh_token'];
    var userId = responseJson['userId'];
    var userName = responseJson['username'];
    var showTutorial = false; //responseJson['showTutorial'];

    isIncognitoMode = false;
    await setInitialUserData(accessToken, refreshToken, userId, userName,
        isSignedInWithThirdPartyServices, showTutorial);
    await storage.write(
        key: 'isIncognitoMode', value: isIncognitoMode.toString());

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
  }

  logout() async {
    isUserAuthorizedOrInIncognitoMode = false;

    notifyListeners();

    userRequested = false;
    user = null;
    userId = null;

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

    await storage.delete(key: 'token');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'userId');
    await storage.delete(key: 'userName');
    await storage.delete(key: 'isSignedInWithGoogle');
    await storage.delete(key: 'isIncognitoMode');
    await storage.delete(key: 'user');
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    token = accessToken;
    this.refreshToken = refreshToken;

    await storage.write(key: 'token', value: token);
    await storage.write(key: 'refreshToken', value: refreshToken);
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
  }

  changeShowTutorialField(bool value) {
    showTutorial = value;

    notifyListeners();
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
