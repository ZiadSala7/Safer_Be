class HotelSearchRoom {
  const HotelSearchRoom({
    this.adults = 2,
    this.children = 0,
    this.childAges = const [],
  });

  final int adults;
  final int children;
  final List<int> childAges;

  int get totalGuests => adults + children;

  HotelSearchRoom copyWith({
    int? adults,
    int? children,
    List<int>? childAges,
  }) => HotelSearchRoom(
    adults: adults ?? this.adults,
    children: children ?? this.children,
    childAges: childAges ?? this.childAges,
  );

  Map<String, dynamic> toJson() => {
    'adults': adults,
    'children': children,
    if (childAges.isNotEmpty) 'child_ages': childAges,
  };

  factory HotelSearchRoom.fromJson(Map<String, dynamic> json) {
    final children = (json['children'] as num?)?.toInt() ?? 0;
    final agesRaw = json['child_ages'] ?? json['childAges'];
    final ages = agesRaw is List
        ? agesRaw.map((e) => (e as num).toInt()).toList()
        : <int>[];
    return HotelSearchRoom(
      adults: (json['adults'] as num?)?.toInt() ?? 1,
      children: children,
      childAges: ages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotelSearchRoom &&
          runtimeType == other.runtimeType &&
          adults == other.adults &&
          children == other.children &&
          _listEquals(childAges, other.childAges);

  @override
  int get hashCode => Object.hash(adults, children, Object.hashAll(childAges));

  static bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class HotelSearch {
  const HotelSearch({
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    this.adults = 2,
    this.children = 0,
    this.childAges = const [],
    this.rooms = 1,
    this.roomList = const [],
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
  final List<HotelSearchRoom> roomList;
  final String currency;
  final String nationality;
  final String? supplier;
  final num? minPrice;
  final num? maxPrice;
  final num? stars;
  final int page;
  final int perPage;

  int get effectiveRooms => roomList.isNotEmpty ? roomList.length : rooms;
  int get effectiveAdults =>
      roomList.isNotEmpty
          ? roomList.fold<int>(0, (sum, r) => sum + r.adults)
          : adults;
  int get effectiveChildren =>
      roomList.isNotEmpty
          ? roomList.fold<int>(0, (sum, r) => sum + r.children)
          : children;
  int get totalGuests => effectiveAdults + effectiveChildren;
  List<int> get effectiveChildAges =>
      roomList.isNotEmpty
          ? roomList.expand((r) => r.childAges).toList()
          : childAges;

  HotelSearch copyWith({
    String? cityCode,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    List<int>? childAges,
    int? rooms,
    List<HotelSearchRoom>? roomList,
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
    roomList: roomList ?? this.roomList,
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
    'adults': effectiveAdults,
    'children': effectiveChildren,
    if (effectiveChildAges.isNotEmpty) 'child_ages': effectiveChildAges,
    'rooms': effectiveRooms,
    if (roomList.isNotEmpty)
      'room_guests': roomList.map((r) => r.toJson()).toList(),
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
