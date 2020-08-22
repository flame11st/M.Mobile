import 'dart:convert';

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

  bool isUserAuthorized = false;
  bool isAppLoaded = false;
  bool isSignedInWithGoogle = false;
  String userName = '';
  String userId = '';
  String token = '';
  String refreshToken = '';
  User user;
  bool showTutorial = false;
  bool isPremium = true;

  void setInitialData() async {
    var storedToken = await storage.read(key: 'token');
    var storedRefreshToken = await storage.read(key: 'refreshToken');
    var storedUserId = await storage.read(key: 'userId');
    var storedUserName = await storage.read(key: 'userName');
    var storedSignedInWithGoogle = await storage.read(key: 'isSignedInWithGoogle');

    this.token = storedToken;
    this.refreshToken = storedRefreshToken;
    this.userId = storedUserId;
    this.userName = storedUserName;
    this.isSignedInWithGoogle = storedSignedInWithGoogle == "true";

    serviceAgent.state = this;
    var authorizationResponse = await serviceAgent.checkAuthorization();
    if (authorizationResponse.statusCode == 200) {
      isUserAuthorized = true;
    }

    isAppLoaded = true;

    notifyListeners();
  }

  void setAppIsLoaded(bool value) {
    isAppLoaded = value;

    notifyListeners();
  }

  processLoginResponse(String response, bool isSignedInWithGoogle) {
    var responseJson = json.decode(response);
    var accessToken = responseJson['access_token'];
    var refreshToken = responseJson['refresh_token'];
    var userId = responseJson['userId'];
    var userName = responseJson['username'];
    var showTutorial = responseJson['showTutorial'];

    setInitialUserData(accessToken, refreshToken, userId, userName, isSignedInWithGoogle, showTutorial);
  }

  logout() async {
    isUserAuthorized = false;
    user = null;
    userId = null;

    await storage.deleteAll();
    notifyListeners();
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    token = accessToken;
    this.refreshToken = refreshToken;

    await storage.write(key: 'token', value: token);
    await storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<void> setInitialUserData(String token, String refreshToken,
      String userId, String userName, bool isSignedInWithGoogle, bool showTutorial) async {
    this.token = token;
    this.refreshToken = refreshToken;
    this.userId = userId;
    this.userName = userName;
    this.isUserAuthorized = true;
    this.isSignedInWithGoogle = isSignedInWithGoogle;
    this.showTutorial = showTutorial;

    notifyListeners();

    await storage.write(key: 'token', value: token);
    await storage.write(key: 'userId', value: userId);
    await storage.write(key: 'userName', value: userName);
    await storage.write(key: 'refreshToken', value: refreshToken);
    await storage.write(key: 'isSignedInWithGoogle', value: isSignedInWithGoogle.toString());
  }

  changeShowTutorialField(bool value) {
    showTutorial = value;

    notifyListeners();
  }
}