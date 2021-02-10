import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Objects/User.dart';
import '../../Services/ServiceAgent.dart';

class UserState with ChangeNotifier {
  UserState() {
    setInitialData();
  }

  final storage = new FlutterSecureStorage();
  final serviceAgent = new ServiceAgent();

  bool isUserAuthorizedOrInIncognitoMode = false;
  bool isAppLoaded = false;
  bool isSignedInWithGoogle = false;
  String userName = '';
  String userId = '';
  String token = '';
  String refreshToken = '';
  User user;
  int androidVersion = 0;
  bool userRequested = false;
  bool showTutorial = false;
  bool isIncognitoMode = false;
  bool premiumPurchasedIncognito = false;
  bool appReviewRequested = false;
  bool shouldRequestReview = false;

  void setInitialData() async {
    var storedToken;
    var storedRefreshToken;
    var storedUserId;
    var storedUserName;
    var storedSignedInWithGoogle;
    var storedUser;
    var storedIsIncognitoMode;
    var storedPremiumPurchasedIncognito;
    var storedAppReviewRequested;

    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      androidVersion = int.parse(androidInfo.version.release.substring(0, 1));
    }

    try {
      storedToken = await storage.read(key: 'token');
      storedRefreshToken = await storage.read(key: 'refreshToken');
      storedUserId = await storage.read(key: 'userId');
      storedUserName = await storage.read(key: 'userName');
      storedSignedInWithGoogle =
          await storage.read(key: 'isSignedInWithGoogle');
      storedIsIncognitoMode = await storage.read(key: 'isIncognitoMode');
      storedPremiumPurchasedIncognito = await storage.read(key: 'premiumPurchasedIncognito');
      storedAppReviewRequested = await storage.read(key: "appReviewRequested");
      storedUser = await storage.read(key: 'user');
    } catch (on, ex) {
      await clearStorage();
    }

    this.appReviewRequested = storedAppReviewRequested == "true";

    if (storedIsIncognitoMode == "true") {
      this.isIncognitoMode = true;
      this.isUserAuthorizedOrInIncognitoMode = true;
      this.isAppLoaded = true;
      this.premiumPurchasedIncognito = storedPremiumPurchasedIncognito == "true";

      notifyListeners();

      return;
    }

    this.token = storedToken;
    this.refreshToken = storedRefreshToken;
    this.userId = storedUserId;
    this.userName = storedUserName;
    this.isSignedInWithGoogle = storedSignedInWithGoogle == "true";

    if (storedUser != null) {
      final userJson = jsonDecode(storedUser);
      this.user = User.fromJson(userJson);
    }

    serviceAgent.state = this;
    var authorizationResponse = await serviceAgent.checkAuthorization();
    if (authorizationResponse.statusCode == 200) {
      isUserAuthorizedOrInIncognitoMode = true;
    }

    isAppLoaded = true;

    notifyListeners();
  }

  get isPremium {
    var result = user != null
        ? user.premiumPurchased != null && user.premiumPurchased
        : premiumPurchasedIncognito;

    return result;
  }

  Future<void> setUser(User user) async {
    this.user = user;

    await storage.write(key: "user", value: jsonEncode(user));
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    if (isIncognitoMode) {
      premiumPurchasedIncognito = true;

      await storage.write(key: "premiumPurchasedIncognito", value: premiumPurchasedIncognito.toString());
    } else {
      user.premiumPurchased = value;

      await storage.write(key: "user", value: jsonEncode(user));
    }

    notifyListeners();
  }

  Future<void> setAppReviewRequested(bool value) async {
    appReviewRequested = value;

    await storage.write(key: "appReviewRequested", value: appReviewRequested.toString());
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

  processLoginResponse(String response, bool isSignedInWithGoogle) {
    var responseJson = json.decode(response);
    var accessToken = responseJson['access_token'];
    var refreshToken = responseJson['refresh_token'];
    var userId = responseJson['userId'];
    var userName = responseJson['username'];
    var showTutorial = false; //responseJson['showTutorial'];

    setInitialUserData(accessToken, refreshToken, userId, userName,
        isSignedInWithGoogle, showTutorial);
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
    this.isUserAuthorizedOrInIncognitoMode = true;
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
}
