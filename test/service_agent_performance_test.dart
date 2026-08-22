import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mmobile/Services/service_agent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String previousBaseUrl;
  late dynamic previousState;

  setUp(() {
    previousBaseUrl = ServiceAgent.baseUrl;
    previousState = ServiceAgent.state;
    ServiceAgent.baseUrl = 'https://moviediary.test/api/';
    ServiceAgent.state = null;
  });

  tearDown(() {
    ServiceAgent.baseUrl = previousBaseUrl;
    ServiceAgent.state = previousState;
  });

  test('identical in-flight GETs share one transport request only', () async {
    var transportCalls = 0;
    final responseCompleter = Completer<http.Response>();
    final client = MockClient((request) {
      transportCalls++;
      return responseCompleter.future;
    });
    final agent = ServiceAgent(client: client);

    final first = agent.get('movies/GetMovie?id=one');
    final duplicate = agent.get('movies/GetMovie?id=one');
    await Future<void>.delayed(Duration.zero);

    expect(transportCalls, 1);
    responseCompleter.complete(http.Response('{"id":"one"}', 200));
    final responses = await Future.wait([first, duplicate]);
    expect(responses.map((response) => response.statusCode), everyElement(200));

    await agent.get('movies/GetMovie?id=one');
    expect(
      transportCalls,
      2,
      reason:
          'Only concurrent work is coalesced; later refreshes remain fresh.',
    );
  });

  test('different GETs and mutations are never coalesced', () async {
    var transportCalls = 0;
    final client = MockClient((request) async {
      transportCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return http.Response('{}', 200);
    });
    final agent = ServiceAgent(client: client);

    await Future.wait([
      agent.get('movies/GetMovie?id=one'),
      agent.get('movies/GetMovie?id=two'),
    ]);
    expect(transportCalls, 2);

    await Future.wait([
      agent.post('User/RateMovie', '{"movieId":"one"}'),
      agent.post('User/RateMovie', '{"movieId":"one"}'),
    ]);
    expect(transportCalls, 4);
  });
}
