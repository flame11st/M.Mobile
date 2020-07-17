import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mmobile/Widgets/Providers/UserState.dart';

class ServiceAgent {
  UserState state;
  final baseUrl = "https://mwebapi1.azurewebsites.net/api/";

//    final baseUrl = "https://localhost:44321/";

  checkAuthorization() {
    return get('Identity/CheckAuthorization');
  }

  login(String email, String password) {
    return post(
        'Identity/login',
        jsonEncode(<String, String>{
          'Email': email,
          'Password': password,
        }));
  }

  getUserMovies(String userId) {
    return get('User/GetUserMovies?userId=$userId');
  }

  getMovie(String movieId) {
    return get('movies/GetMovie?id=$movieId');
  }

  search(String query) {
    return get('movies/Search?query=$query');
  }

  rateMovie(String movieId, String userId, int movieRate) {
    return post('User/RateMovie', jsonEncode({
      'MovieId': movieId,
      'UserId': userId,
      'MovieRate': movieRate,
    }));
  }

  get(String uri) async {
    Map<String, String> headers = {};
    if (state != null) headers.putIfAbsent(HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

    var response = await http.get(baseUrl + uri, headers: headers);

    if (response.statusCode == 401) {
      headers.clear();
      bool isTokenRefreshed = await refreshAccessToken();
      if (isTokenRefreshed) {
        if (state != null) headers.putIfAbsent(HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

        response = await http.get(baseUrl + uri, headers: headers);
      }
    }

    return response;
  }

  post(String uri, postData) async {
    var headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (state != null) headers.putIfAbsent(HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

    var response = await http.post(baseUrl + uri, body: postData, headers: headers);

    if (response.statusCode == 401) {
      bool isTokenRefreshed = await refreshAccessToken();
      if (isTokenRefreshed) {
        response = await http.post(baseUrl + uri, body: postData, headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          HttpHeaders.authorizationHeader: "Bearer ${state.token}"
        });
      }
    }

    return response;
  }

  Future<bool> refreshAccessToken() async {
    var response = await http.get(
        baseUrl + 'Identity/RefreshTokenMobile?token=${state.refreshToken}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      state.setTokens(
          responseData['access_token'], responseData['refresh_token']);

      return true;
    }

    return false;
  }
}
