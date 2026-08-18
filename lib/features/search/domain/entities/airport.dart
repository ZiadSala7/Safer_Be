import '../../../../core/network/json_read.dart';

class Airport {
  const Airport({required this.code, required this.name, required this.city});

  final String code;
  final String name;
  final String city;

  factory Airport.fromJson(Map<String, dynamic> json) => Airport(
    code: readText(json, ['iataCode', 'code', 'iata_code', 'airport_code']),
    name: readText(json, ['name', 'airport_name']),
    city: readText(json, ['city', 'city_name']),
  );
}
