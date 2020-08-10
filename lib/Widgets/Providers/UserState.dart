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

  void setInitialData() async {
    var storedToken = await storage.read(key: 'token');
    var storedRefreshToken = await storage.read(key: 'refreshToken');
    var storedUserId = await storage.read(key: 'userId');
    var storedUserName = await storage.read(key: 'userName');

    this.token = storedToken;
    this.refreshToken = storedRefreshToken;
    this.userId = storedUserId;
    this.userName = storedUserName;

    serviceAgent.state = this;
    var authorizationResponse = await serviceAgent.checkAuthorization();
    if (authorizationResponse.statusCode == 200) {
      isUserAuthorized = true;
    }

    isAppLoaded = true;

    notifyListeners();
  }

  processLoginResponse(String response, bool isSignedInWithGoogle) {
    var responseJson = json.decode(response);
    var accessToken = responseJson['access_token'];
    var refreshToken = responseJson['refresh_token'];
    var userId = responseJson['userId'];
    var userName = responseJson['username'];

    isSignedInWithGoogle = isSignedInWithGoogle;
    setInitialUserData(accessToken, refreshToken, userId, userName);
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
      String userId, String userName) async {
    this.token = token;
    this.refreshToken = refreshToken;
    this.userId = userId;
    this.userName = userName;
    this.isUserAuthorized = true;

    notifyListeners();

    await storage.write(key: 'token', value: token);
    await storage.write(key: 'userId', value: userId);
    await storage.write(key: 'userName', value: userName);
    await storage.write(key: 'refreshToken', value: refreshToken);
  }
}