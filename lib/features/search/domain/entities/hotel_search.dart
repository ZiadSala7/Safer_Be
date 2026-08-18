class HotelSearch {
  const HotelSearch({
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
  });

  final String cityCode;
  final DateTime checkIn;
  final DateTime checkOut;

  Map<String, dynamic> toJson() => {
    'city_code': cityCode,
    'check_in': checkIn.toIso8601String().split('T').first,
    'check_out': checkOut.toIso8601String().split('T').first,
    'adults': 2,
    'children': 0,
    'child_ages': <int>[],
    'nationality': 'SA',
    'currency': 'SAR',
    'supplier': 'tbo_hotels',
    'page': 1,
    'per_page': 20,
  };
}
