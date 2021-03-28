import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mmobile/Widgets/Providers/UserState.dart';

class ServiceAgent {
  UserState state;
  String baseUrl = "";
  final functionUriAWS = "https://fe6b8miszj.execute-api.us-east-2.amazonaws.com/default/Function1";

  var baseUrlLocal = "http://192.168.31.60/";

  ServiceAgent() {
    setBaseUrl();
  }

  setBaseUrl() async {
    var url = await getBaseUrl();

    this.baseUrl = url;
  }

  getBaseUrl() async {
    var responseAWS = await http.get(functionUriAWS);

    var uri = responseAWS.body;

    return uri + "/api/";
    // return baseUrlLocal + "api/";
  }

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

  getMoviesByIds(String ids) {
    return get('movies/GetMoviesByIds?ids=$ids');
  }

  reloadMoviePoster(String movieId) {
    return get('movies/ReloadMoviePoster?id=$movieId');
  }

  getMoviesLists(String userId) {
    return get('movies/GetMoviesListsStringValue?userId=$userId');
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
    if (state != null)
      headers.putIfAbsent(
          HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

    var response = await http.get(baseUri + uri, headers: headers);

    if (response.statusCode == 401) {
      headers.clear();
      bool isTokenRefreshed = await refreshAccessToken();
      if (isTokenRefreshed) {
        if (state != null)
          headers.putIfAbsent(
              HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

        response = await http.get(baseUri + uri, headers: headers);
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
    if (state != null)
      headers.putIfAbsent(
          HttpHeaders.authorizationHeader, () => "Bearer ${state.token}");

    var response =
        await http.post(baseUri + uri, body: postData, headers: headers);

    if (response.statusCode == 401) {
      bool isTokenRefreshed = await refreshAccessToken();
      if (isTokenRefreshed) {
        response = await http
            .post(baseUri + uri, body: postData, headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          HttpHeaders.authorizationHeader: "Bearer ${state.token}"
        });
      }
    }

    return response;
  }

  Future<bool> refreshAccessToken() async {
    var baseUri = baseUrl;

    if (baseUri == "") {
      baseUri = await getBaseUrl();
    }

    var response = await http.get(
        baseUri + 'Identity/RefreshTokenMobile?token=${state.refreshToken}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      state.setTokens(
          responseData['access_token'], responseData['refresh_token']);

      return true;
    }

    return false;
  }
}
