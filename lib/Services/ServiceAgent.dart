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

  signUp(String name, String email, String password) {
    return post(
        'Identity/SignUp',
        jsonEncode(<String, String>{
          'Email': email,
          'Name': name,
          'Password': password,
        }));
  }

  googleLogin(String idToken) {
    return get('Identity/GoogleLoginAndroid?idToken=$idToken');
  }

  getUserMovies(String userId) {
    return get('User/GetUserMovies?userId=$userId');
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

  deleteUser(String userId) {
    return get('User/DeleteUser?userId=$userId');
  }


  setUserPremiumPurchased(String userId, bool value) {
    return get('User/SetUserPremiumPurchased?userId=$userId&value=$value');
  }

  getMovie(String movieId) {
    return get('movies/GetMovie?id=$movieId');
  }

  reloadMoviePoster(String movieId) {
    return get('movies/ReloadMoviePoster?id=$movieId');
  }

  getMoviesLists() {
    return get('movies/GetMoviesLists');
  }

  search(String query) {
    return get('movies/SearchByIndexedColumn?query=$query');
  }

  advancedSearch(String query) {
    return get('movies/AdvancedSearch?query=$query');
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

  get(String uri) async {
    Map<String, String> headers = {};
    if (state != null)
      headers.putIfAbsent(
          HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

    var response = await http.get(baseUrl + uri, headers: headers);

    if (response.statusCode == 401) {
      headers.clear();
      bool isTokenRefreshed = await refreshAccessToken();
      if (isTokenRefreshed) {
        if (state != null)
          headers.putIfAbsent(
              HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

        response = await http.get(baseUrl + uri, headers: headers);
      }
    }

    return response;
  }

  post(String uri, postData) async {
    var headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (state != null)
      headers.putIfAbsent(
          HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

    var response =
        await http.post(baseUrl + uri, body: postData, headers: headers);

    if (response.statusCode == 401) {
      bool isTokenRefreshed = await refreshAccessToken();
      if (isTokenRefreshed) {
        response = await http
            .post(baseUrl + uri, body: postData, headers: <String, String>{
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
