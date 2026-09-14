import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rlgpro_app/data/api_client.dart';
import 'package:rlgpro_app/data/api_exception.dart';
import 'package:rlgpro_app/data/token_store.dart';
import 'package:rlgpro_app/models/action_config.dart';

class MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<void> clear() async => token = null;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async => token = value;
}

void main() {
  test('login stores token securely and maps profile', () async {
    final store = MemoryTokenStore();
    final client = ApiClient(
      baseUrl: 'https://api.test/api',
      tokenStore: store,
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(jsonDecode(request.body)['password'], 'secret123');
        return http.Response(
          jsonEncode({
            'token': 'sanctum-token',
            'user': {
              'id': 1,
              'first_name': 'Ada',
              'last_name': 'Lovelace',
              'username': 'ada',
              'status': 'active',
            },
          }),
          200,
        );
      }),
    );

    final user = await client.login('ada', 'secret123');
    expect(user.fullName, 'Ada Lovelace');
    expect(store.token, 'sanctum-token');
  });

  test('401 clears token and invokes session expiry callback', () async {
    final store = MemoryTokenStore()..token = 'expired';
    var expired = false;
    final client = ApiClient(
      baseUrl: 'https://api.test/api',
      tokenStore: store,
      client: MockClient(
        (_) async => http.Response('{"message":"Unauthenticated."}', 401),
      ),
    )..onUnauthorized = () async => expired = true;

    await expectLater(client.me(), throwsA(isA<ApiException>()));
    expect(store.token, isNull);
    expect(expired, isTrue);
  });

  test('customer list sends per_page as a query parameter', () async {
    final store = MemoryTokenStore()..token = 'token';
    final client = ApiClient(
      baseUrl: 'https://api.test/api',
      tokenStore: store,
      client: MockClient((request) async {
        expect(request.url.path, '/api/admin/customers');
        expect(request.url.queryParameters['per_page'], '100');
        expect(request.url.toString(), isNot(contains('%3F')));

        return http.Response('{"data":[]}', 200);
      }),
    );

    expect(await client.getCustomers(), isEmpty);
  });

  test('admin settings accept PHP empty arrays for headers and body', () {
    final settings = AdminSettings.fromJson({
      'hape': {
        'url': 'https://example.test/open',
        'method': 'POST',
        'headers': <dynamic>[],
        'body': <dynamic>[],
      },
      'mbylle': null,
    });

    expect(settings.hape.headers, isEmpty);
    expect(settings.hape.body, isEmpty);
    expect(settings.mbylle.url, isEmpty);
  });
}
