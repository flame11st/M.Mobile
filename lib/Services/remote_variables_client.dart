import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class RemoteVariablesClient {
  RemoteVariablesClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client;

  static final Uri endpoint = Uri.parse(
    'https://fe6b8miszj.execute-api.us-east-2.amazonaws.com/'
    'default/GetMovieDiaryVariables',
  );

  final http.Client? _client;
  final Duration timeout;

  Future<Map<String, dynamic>> fetch() async {
    final response =
        await (_client?.get(endpoint) ?? http.get(endpoint)).timeout(timeout);
    if (response.statusCode != 200) {
      throw HttpException(
        'Remote variables request failed with ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Remote variables must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
