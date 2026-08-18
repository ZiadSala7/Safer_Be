import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safer_be_project/core/network/api_client.dart';
import 'package:safer_be_project/core/network/api_exception.dart';
import 'package:safer_be_project/features/search/data/repositories/api_travel_search_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'client uses the production base URL and standard API headers',
    () async {
      late http.Request captured;
      final client = ApiClient(
        language: 'ar',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'success': true, 'airports': <Object>[]}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await client.get('/flights/airports', query: {'search': 'CAI'});

      expect(
        captured.url.toString(),
        'https://backend.saferbe.com/api/v1/flights/airports?search=CAI',
      );
      expect(captured.headers['Accept'], 'application/json');
      expect(captured.headers['Accept-Language'], 'ar');
    },
  );

  test('client exposes API validation messages and fields', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'The origin field is required.',
            'errors': {
              'Origin': ['Origin is required.'],
            },
          }),
          422,
        ),
      ),
    );

    await expectLater(
      client.post('/flights/search', body: const {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.message,
              'message',
              'The origin field is required.',
            )
            .having((error) => error.errors['Origin'], 'field error', [
              'Origin is required.',
            ]),
      ),
    );
  });

  test('search repository reads live airport envelopes', () async {
    final repository = ApiTravelSearchRepository(
      client: ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'airports': [
                {'code': 'CAI', 'name': 'Cairo International', 'city': 'Cairo'},
              ],
              'total': 1,
            }),
            200,
          ),
        ),
      ),
    );

    final airports = await repository.airports('cairo');

    expect(airports, hasLength(1));
    expect(airports.single.code, 'CAI');
  });
}
