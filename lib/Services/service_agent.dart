import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';
import 'package:mmobile/Objects/movie_watch_provider_group.dart';
import 'package:mmobile/Objects/recommendation_discovery_session.dart';
import 'package:mmobile/Objects/user_taste_profile.dart';

class ServiceAgent {
  static dynamic state;
  static String baseUrl = "";
  static const configuredBaseUrl =
      String.fromEnvironment('MOVIEDIARY_API_BASE_URL');
  static const baseUrlTimeout = Duration(seconds: 5);
  static const requestTimeout = Duration(seconds: 12);
  final functionUriAWS =
      "https://fe6b8miszj.execute-api.us-east-2.amazonaws.com/default/GetMovieDiaryVariables";
  static bool showLoadingAd = false;
  final String baseUrlLocal = kDebugMode
      ? (Platform.isAndroid
          ? "http://10.0.2.2:5000/"
          : "http://localhost:5000/")
      : "http://51.81.79.14/";

  ServiceAgent() {
    if (baseUrl.isEmpty) setBaseUrl();
  }

  setBaseUrl() async {
    var url = await getBaseUrl();

    baseUrl = url;
  }

  getBaseUrl() async {
    if (configuredBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(configuredBaseUrl);
    }

    if (kDebugMode) {
      return _normalizeBaseUrl(baseUrlLocal);
    }

    try {
      var responseAWS =
          await http.get(Uri.parse(functionUriAWS)).timeout(baseUrlTimeout);
      if (responseAWS.statusCode == 200) {
        var variables = jsonDecode(responseAWS.body);
        var uri = variables["apiUrl"];
        showLoadingAd = variables["showLoadingAd"] ?? false;
        return "$uri/api/";
      }
    } catch (e) {
      debugPrint("Error fetching base URL from AWS: $e");
    }
    return _normalizeBaseUrl(baseUrlLocal);
  }

  String _normalizeBaseUrl(String url) {
    final parsedUrl = Uri.parse(url);
    final emulatorSafeUrl =
        Platform.isAndroid && parsedUrl.host.toLowerCase() == 'localhost'
            ? parsedUrl.replace(host: '10.0.2.2').toString()
            : url;

    return emulatorSafeUrl.endsWith("/")
        ? emulatorSafeUrl
        : "$emulatorSafeUrl/";
  }

  checkAuthorization() {
    return get('Identity/CheckAuthorization');
  }

  login(String email, String password, {String? incognitoUserId}) {
    return post(
        'Identity/login',
        jsonEncode({
          'Email': email,
          'Password': password,
          if (incognitoUserId != null) 'IncognitoUserId': incognitoUserId,
        }));
  }

  requestPasswordReset(String email) {
    return post(
      'Identity/RequestPasswordReset',
      jsonEncode({'Email': email}),
    );
  }

  signInIncognito() {
    return post('Identity/SignUpIncognito', '');
  }

  signUp(String name, String email, String password,
      {String? incognitoUserId}) {
    return post(
        'Identity/SignUp',
        jsonEncode({
          'Email': email,
          'Name': name,
          'Password': password,
          if (incognitoUserId != null) 'IncognitoUserId': incognitoUserId,
        }));
  }

  googleLogin(String idToken, {String? incognitoUserId}) {
    return get(_authUri('Identity/GoogleLoginAndroid', {
      'idToken': idToken,
      if (incognitoUserId != null) 'incognitoUserId': incognitoUserId,
    }));
  }

  googleLoginIOS(String idToken, {String? incognitoUserId}) {
    return get(_authUri('Identity/GoogleLoginIOS', {
      'idToken': idToken,
      if (incognitoUserId != null) 'incognitoUserId': incognitoUserId,
    }));
  }

  appleLogin(String appleId, String email, String name,
      {String? incognitoUserId}) {
    return get(_authUri('Identity/AppleLogin', {
      'appleId': appleId,
      'email': email,
      'name': name,
      if (incognitoUserId != null) 'incognitoUserId': incognitoUserId,
    }));
  }

  String _authUri(String path, Map<String, String> params) {
    return Uri(path: path, queryParameters: params).toString();
  }

  getUserMovies(String userId) {
    return get('User/GetUserMovies?userId=$userId');
  }

  getUserRecommendations(String userId, MovieType type) {
    return get(
        'Recommendations/GetUserMoviesRecommendations?userId=$userId&movieType=${type.index}');
  }

  getUserRecommendationsHistory(String userId) {
    return get(
        'Recommendations/GetUserMoviesRecommendationsHistory?userId=$userId');
  }

  Future<UserTasteProfile> getUserTasteProfile(String userId) async {
    final response =
        await get('Recommendations/GetUserTasteProfile?userId=$userId');

    if (response.statusCode != 200) {
      throw HttpException(
          'Taste profile request failed with ${response.statusCode}');
    }

    return UserTasteProfile.fromJson(jsonDecode(response.body));
  }

  Future<UserTasteProfile> regenerateUserTasteProfile(String userId) async {
    final response = await post(
        'Recommendations/RegenerateUserTasteProfile?userId=$userId', '');

    if (response.statusCode != 200) {
      throw HttpException(
          'Taste profile regeneration failed with ${response.statusCode}');
    }

    return UserTasteProfile.fromJson(jsonDecode(response.body));
  }

  Future<RecommendationDiscoverySession?> createDiscoverySession(
    String userId,
    MovieType movieType,
    RecommendationDiscoveryLevel discoveryLevel,
    int pageSize, {
    String? previousSessionId,
    Iterable<String> excludedMovieIds = const [],
  }) async {
    final excludedIds = excludedMovieIds
        .where((movieId) => movieId.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final response = await post(
        'Recommendations/CreateDiscoverySession',
        jsonEncode({
          'UserId': userId,
          'MovieType': movieType.index,
          'DiscoveryLevel': discoveryLevel.index,
          'PageSize': pageSize,
          if (previousSessionId != null && previousSessionId.isNotEmpty)
            'PreviousSessionId': previousSessionId,
          if (excludedIds.isNotEmpty) 'ExcludedMovieIds': excludedIds,
        }));

    if (response.statusCode != 200) {
      return null;
    }

    return RecommendationDiscoverySession.fromJson(jsonDecode(response.body));
  }

  Future<RecommendationDiscoverySession?> getDiscoverySessionPage(
      String sessionId, int cursor, int pageSize) async {
    final response = await get(
        'Recommendations/GetDiscoverySessionPage?sessionId=$sessionId&cursor=$cursor&pageSize=$pageSize');

    if (response.statusCode != 200) {
      return null;
    }

    return RecommendationDiscoverySession.fromJson(jsonDecode(response.body));
  }

  getMovieRecommendationsByTitles(String titles, MovieType type) {
    return get(
        'Recommendations/GetMoviesRecommendationsByTitles?titles=$titles&movieType=${type.index}');
  }

  getUserInfo(String userId) {
    return get('User/GetUserInfo?userId=$userId');
  }

  changeUserInfo(String userId, String name, String email) {
    return post(
        'User/ChangeUserInfo',
        jsonEncode(<String, String>{
          'Id': userId,
          'Name': name,
          'Email': email,
        }));
  }

  deleteUser(String userId, String feedback) {
    return post(
        'User/DeleteUserWithFeedback',
        jsonEncode(<String, String>{
          'Id': userId,
          'Feedback': feedback,
        }));
  }

  changeUserPassword(String userId, String oldPassword, String newPassword) {
    return post(
        'User/ChangeUserPassword',
        jsonEncode(<String, String>{
          'UserId': userId,
          'OldPassword': oldPassword,
          'NewPassword': newPassword,
        }));
  }

  clearUserMovies(String userId) {
    return get('User/ClearUserMovies?userId=$userId');
  }

  setUserPremiumPurchased(String userId, bool value) {
    return get('User/SetUserPremiumPurchased?userId=$userId&value=$value');
  }

  getMovie(String movieId) {
    return get('movies/GetMovie?id=$movieId');
  }

  Future<MovieWatchProviderGroup> getWhereToWatchGrouped(
      String movieId, String country) async {
    final response = await get(
        'movies/GetWhereToWatchGrouped?movieId=$movieId&country=$country');

    if (response.statusCode != 200) {
      return MovieWatchProviderGroup.empty(movieId, country);
    }

    return MovieWatchProviderGroup.fromJson(jsonDecode(response.body));
  }

  getMoviesByIds(String ids) {
    return get('movies/GetMoviesByIds?ids=$ids');
  }

  reloadMoviePoster(String movieId) {
    return get('movies/ReloadMoviePoster?id=$movieId');
  }

  getMoviesLists(String userId) {
    return get('movies/GetMoviesListsStringValue?userId=$userId');
  }

  getStarterDeck({int perBucket = 20}) {
    return get('movies/GetStarterDeck?perBucket=$perBucket');
  }

  search(String query) {
    return get('movies/SearchByIndexedColumn?query=$query');
  }

  advancedSearch(String query) {
    return get('movies/AdvancedSearch?query=$query');
  }

  getPopularSearches({int limit = 6, int days = 30}) {
    return get('movies/GetPopularSearches?limit=$limit&days=$days');
  }

  rateMovie(String movieId, String userId, int movieRate) {
    return post(
        'User/RateMovie',
        jsonEncode({
          'MovieId': movieId,
          'UserId': userId,
          'MovieRate': movieRate,
        }));
  }

  createUserMoviesList(String userId, String listName, int order) {
    return post(
        'Movies/CreateUserMoviesList',
        jsonEncode({
          'UserId': userId,
          'Order': order,
          'ListName': listName,
        }));
  }

  renameUserMoviesList(String userId, String oldName, String newName) {
    return post(
        'Movies/RenameUserMoviesList',
        jsonEncode({
          'UserId': userId,
          'OldName': oldName,
          'NewName': newName,
        }));
  }

  removeUserMoviesList(String userId, String listName) {
    return post(
        'Movies/RemoveUserMoviesList',
        jsonEncode({
          'UserId': userId,
          'ListName': listName,
        }));
  }

  addMovieToList(String userId, String movieId, String listName) {
    return post(
        'Movies/AddMovieToList',
        jsonEncode({
          'UserId': userId,
          'MovieId': movieId,
          'ListName': listName,
        }));
  }

  removeMovieFromList(String userId, String movieId, String listName) {
    return post(
        'Movies/RemoveMovieFromList',
        jsonEncode({
          'UserId': userId,
          'MovieId': movieId,
          'ListName': listName,
        }));
  }

  get(String uri) async {
    var baseUri = baseUrl;

    if (baseUri == "") {
      baseUri = await getBaseUrl();
    }

    Map<String, String> headers = {};
    if (state != null) {
      headers.putIfAbsent(
          HttpHeaders.authorizationHeader, () => "Bearer ${state?.token}");
    }

    var fullUri = Uri.parse(baseUri + uri);
    var response = await http.get(fullUri, headers: headers).timeout(
          requestTimeout,
        );

    if (response.statusCode == 401) {
      headers.clear();
      bool isTokenRefreshed = await refreshAccessToken();
      if (isTokenRefreshed) {
        if (state != null) {
          headers.putIfAbsent(
              HttpHeaders.authorizationHeader, () => "Bearer ${state?.token}");
        }

        response =
            await http.get(Uri.parse(baseUri + uri), headers: headers).timeout(
                  requestTimeout,
                );
      }
    }

    return response;
  }

  post(String uri, postData) async {
    var baseUri = baseUrl;

    if (baseUri == "") {
      baseUri = await getBaseUrl();
    }

    var headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (state != null) {
      headers.putIfAbsent(
          HttpHeaders.authorizationHeader, () => "Bearer ${state?.token}");
    }

    var response = await http
        .post(Uri.parse(baseUri + uri), body: postData, headers: headers)
        .timeout(
          requestTimeout,
        );

    if (response.statusCode == 401) {
      bool isTokenRefreshed = await refreshAccessToken();
      if (isTokenRefreshed) {
        response = await http.post(Uri.parse(baseUri + uri),
            body: postData,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              HttpHeaders.authorizationHeader: "Bearer ${state?.token}"
            }).timeout(
          requestTimeout,
        );
      }
    }

    return response;
  }

  Future<bool> refreshAccessToken() async {
    var baseUri = baseUrl;

    if (baseUri == "") {
      baseUri = await getBaseUrl();
    }

    var response = await http
        .get(Uri.parse(
            '${baseUri}Identity/RefreshTokenMobile?token=${state?.refreshToken}'))
        .timeout(
          requestTimeout,
        );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      state?.setTokens(
          responseData['access_token'], responseData['refresh_token']);

      return true;
    }

    return false;
  }
}
