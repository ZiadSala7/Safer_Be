class HotelSearch {
  const HotelSearch({
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    this.adults = 2,
    this.children = 0,
    this.childAges = const [],
    this.rooms = 1,
    this.currency = 'SAR',
    this.nationality = 'SA',
    this.supplier,
    this.minPrice,
    this.maxPrice,
    this.stars,
    this.page = 1,
    this.perPage = 20,
  });

  final String cityCode;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final List<int> childAges;
  final int rooms;
  final String currency;
  final String nationality;
  final String? supplier;
  final num? minPrice;
  final num? maxPrice;
  final num? stars;
  final int page;
  final int perPage;

  HotelSearch copyWith({
    String? cityCode,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    List<int>? childAges,
    int? rooms,
    String? currency,
    String? nationality,
    String? supplier,
    num? minPrice,
    num? maxPrice,
    num? stars,
    int? page,
    int? perPage,
  }) => HotelSearch(
    cityCode: cityCode ?? this.cityCode,
    checkIn: checkIn ?? this.checkIn,
    checkOut: checkOut ?? this.checkOut,
    adults: adults ?? this.adults,
    children: children ?? this.children,
    childAges: childAges ?? this.childAges,
    rooms: rooms ?? this.rooms,
    currency: currency ?? this.currency,
    nationality: nationality ?? this.nationality,
    supplier: supplier ?? this.supplier,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    stars: stars ?? this.stars,
    page: page ?? this.page,
    perPage: perPage ?? this.perPage,
  );

  Map<String, dynamic> toJson() => {
    'city_code': cityCode.trim(),
    'check_in': checkIn.toIso8601String().split('T').first,
    'check_out': checkOut.toIso8601String().split('T').first,
    'adults': adults,
    'children': children,
    if (childAges.isNotEmpty) 'child_ages': childAges,
    'rooms': rooms,
    'nationality': nationality.isNotEmpty ? nationality : 'SA',
    'currency': currency.isNotEmpty ? currency : 'SAR',
    if (supplier != null && supplier!.isNotEmpty) 'supplier': supplier,
    if (minPrice != null) 'min_price': minPrice,
    if (maxPrice != null) 'max_price': maxPrice,
    if (stars != null) 'stars': stars,
    'page': page,
    'per_page': perPage,
  };
}
