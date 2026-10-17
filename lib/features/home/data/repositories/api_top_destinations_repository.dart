import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_read.dart';
import '../../../../core/utils/guid_generator.dart';
import '../../domain/entities/top_destination_item.dart';

class ApiTopDestinationsRepository {
  ApiTopDestinationsRepository({ApiClient? client})
      : _client = client ?? ApiClient();

  final ApiClient _client;
  List<TopDestinationItem>? _cached;

  List<TopDestinationItem> get defaultDestinations => _cached ?? _defaultDestinations;

  Future<List<TopDestinationItem>> getTopDestinations({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cached != null && _cached!.isNotEmpty) {
      return _cached!;
    }

    try {
      final json = await _client.get(
        '/hotels/reference/top-destinations',
        authenticated: false,
        headers: {'X-Request-Id': generateGuid()},
      );

      final list = apiList(json);
      if (list.isNotEmpty) {
        final items = list
            .map((item) => TopDestinationItem.fromJson(item))
            .where((item) => item.cityName.isNotEmpty)
            .toList();

        items.sort((a, b) {
          final rA = a.rank > 0 ? a.rank : 999;
          final rB = b.rank > 0 ? b.rank : 999;
          if (rA != rB) return rA.compareTo(rB);
          return a.cityName.compareTo(b.cityName);
        });

        if (items.isNotEmpty) {
          _cached = items;
          return items;
        }
      }
    } catch (_) {
      // Graceful fallback to default destinations
    }

    return _defaultDestinations;
  }

  static final List<TopDestinationItem> _defaultDestinations = [
    TopDestinationItem.fromJson(const {
      'city_id': 3,
      'city_code': '109198',
      'city_name': 'Amman',
      'country_code': 'JO',
      'country_name': 'Jordan',
      'rank': 1,
      'destination_code': '109198',
    }),
    TopDestinationItem.fromJson(const {
      'city_id': 9,
      'city_code': '115936',
      'city_name': 'Dubai',
      'country_code': 'AE',
      'country_name': 'United Arab Emirates',
      'rank': 2,
      'destination_code': '115936',
    }),
    TopDestinationItem.fromJson(const {
      'city_id': 4,
      'city_code': '109723',
      'city_name': 'Bahrain',
      'country_code': 'BH',
      'country_name': 'Bahrain',
      'rank': 3,
      'destination_code': '109723',
    }),
    TopDestinationItem.fromJson(const {
      'city_id': 8,
      'city_code': '126389',
      'city_name': 'Manama',
      'country_code': 'BH',
      'country_name': 'Bahrain',
      'rank': 4,
      'destination_code': '126389',
    }),
    TopDestinationItem.fromJson(const {
      'city_id': 5,
      'city_code': '135316',
      'city_name': 'Salalah',
      'country_code': 'OM',
      'country_name': 'Oman',
      'rank': 5,
      'destination_code': '135316',
    }),
    TopDestinationItem.fromJson(const {
      'city_id': 7,
      'city_code': '151798',
      'city_name': 'Nice',
      'country_code': 'FR',
      'country_name': 'France',
      'rank': 6,
      'destination_code': '151798',
    }),
    TopDestinationItem.fromJson(const {
      'city_id': 6,
      'city_code': '136014',
      'city_name': 'San Francisco',
      'country_code': 'US',
      'country_name': 'United States',
      'rank': 7,
      'destination_code': '136014',
    }),
    TopDestinationItem.fromJson(const {
      'city_id': 10,
      'city_code': '130443',
      'city_name': 'New Delhi / Delhi',
      'country_code': 'IN',
      'country_name': 'India',
      'rank': 8,
      'destination_code': '130443',
    }),
  ];
}
