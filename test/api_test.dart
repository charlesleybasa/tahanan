import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahanan/data/api/api_client.dart';
import 'package:tahanan/data/api/api_config.dart';
import 'package:tahanan/data/repositories.dart';

// The bundled assets/data/*.json files double as the API's sample responses; these tests serve them through a
// fake server to prove the HTTP repositories, auth headers, envelope handling and token refresh work.

const _config = ApiConfig(baseUrl: 'https://api.test/api/v1', useMockData: false);

http.Response _res(String body, int status, {Map<String, String> headers = const {}}) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8', ...headers},
);

String _fixture(String name) => File('assets/data/$name.json').readAsStringSync();

void main() {
  test('Catalog parses the documented brands payload (bare and { data } envelope)', () async {
    for (final wrap in [false, true]) {
      final api = ApiClient(
        _config,
        http: MockClient((req) async {
          expect(req.url.toString(), 'https://api.test/api/v1/brands');
          final body = _fixture('brands');
          return _res(wrap ? '{"data": $body}' : body, 200, headers: {'content-type': 'application/json'});
        }),
      );
      final brands = await Repositories.http(api).projects.brands();
      expect(brands, hasLength(9));
      expect(brands.first.locations!.first.products!.first.financing!.gmi, 14056);
    }
  });

  test('Sign-in stores the session and sends the bearer token', () async {
    final api = ApiClient(
      _config,
      http: MockClient((req) async {
        if (req.url.path.endsWith('/auth/sign-in')) {
          expect(jsonDecode(req.body), {'email': 'maria@example.com', 'password': 'secret'});
          return _res('{"accessToken":"a1","refreshToken":"r1"}', 200);
        }
        expect(req.headers['Authorization'], 'Bearer a1');
        return _res(_fixture('profile'), 200);
      }),
    );
    final repos = Repositories.http(api);
    await repos.auth.signIn(email: 'maria@example.com', password: 'secret');
    final me = await repos.buyer.profile();
    expect(me.grossMonthlyIncome, 22000);
  });

  test('A 401 refreshes the token once and retries', () async {
    var calls = 0;
    final tokens = MemoryTokenStore();
    await tokens.save(accessToken: 'expired', refreshToken: 'r1');
    final api = ApiClient(
      _config,
      tokens: tokens,
      http: MockClient((req) async {
        if (req.url.path.endsWith('/auth/refresh')) return _res('{"accessToken":"fresh"}', 200);
        calls++;
        return req.headers['Authorization'] == 'Bearer fresh'
            ? _res(_fixture('transactions'), 200)
            : _res('{"error":{"message":"Session expired"}}', 401);
      }),
    );
    final tx = await Repositories.http(api).buyer.transactions();
    expect(tx, isNotEmpty);
    expect(calls, 2);
    expect(tokens.accessToken, 'fresh');
  });

  test('Errors surface the server message', () async {
    final api = ApiClient(_config, http: MockClient((_) async => _res('{"message":"Invalid email or password"}', 400)));
    expect(
      () => Repositories.http(api).auth.signIn(email: 'x', password: 'y'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Invalid email or password')),
    );
  });
}
