import '../../../../core/network/json_read.dart';

class TravelCity {
  const TravelCity({
    required this.code,
    required this.name,
    required this.country,
  });

  final String code;
  final String name;
  final String country;

  factory TravelCity.fromJson(Map<String, dynamic> json) => TravelCity(
    code: readText(json, ['hotel_city_code', 'city_code', 'code', 'id']),
    name: readText(json, ['name', 'city_name']),
    country: readText(json, ['countryName', 'country_name', 'country']),
  );
}
