class FlightSearch {
  const FlightSearch({
    required this.origin,
    required this.destination,
    required this.departure,
    this.returnDate,
    this.tripType,
    this.segments = const [],
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = 1,
    this.currency = 'USD',
    this.preferredAirlines = const [],
    this.filters,
    this.sort,
    this.flightType = 'search',
    this.limit = 3,
    this.searchId,
    this.endUserIp,
  });

  final String origin;
  final String destination;
  final DateTime departure;
  final DateTime? returnDate;
  final String? tripType;
  final List<FlightSearchSegment> segments;
  final int adults;
  final int children;
  final int infants;
  final int cabinClass;
  final String currency;
  final List<String> preferredAirlines;
  final FlightSearchFilters? filters;
  final String? sort;
  final String flightType;
  final int limit;
  final String? searchId;
  final String? endUserIp;

  int get journeyType {
    if (segments.isNotEmpty || tripType == 'multi-city') return 3;
    return returnDate == null ? 1 : 2;
  }

  FlightSearch copyWith({
    String? origin,
    String? destination,
    DateTime? departure,
    DateTime? returnDate,
    bool clearReturnDate = false,
    String? tripType,
    List<FlightSearchSegment>? segments,
    int? adults,
    int? children,
    int? infants,
    int? cabinClass,
    String? currency,
    List<String>? preferredAirlines,
    FlightSearchFilters? filters,
    bool clearFilters = false,
    String? sort,
    bool clearSort = false,
    String? flightType,
    int? limit,
    String? searchId,
    bool clearSearchId = false,
    String? endUserIp,
  }) => FlightSearch(
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    departure: departure ?? this.departure,
    returnDate: clearReturnDate ? null : returnDate ?? this.returnDate,
    tripType: tripType ?? this.tripType,
    segments: segments ?? this.segments,
    adults: adults ?? this.adults,
    children: children ?? this.children,
    infants: infants ?? this.infants,
    cabinClass: cabinClass ?? this.cabinClass,
    currency: normalizeCurrency(currency ?? this.currency),
    preferredAirlines: preferredAirlines ?? this.preferredAirlines,
    filters: clearFilters ? null : filters ?? this.filters,
    sort: clearSort ? null : sort ?? this.sort,
    flightType: flightType ?? this.flightType,
    limit: limit ?? this.limit,
    searchId: clearSearchId ? null : searchId ?? this.searchId,
    endUserIp: endUserIp ?? this.endUserIp,
  );

  String get serverSearchKey {
    final segmentKey = segments
        .map((s) => '${s.origin}|${s.destination}|${_date(s.departure)}')
        .join(',');
    return [
      origin,
      destination,
      _date(departure),
      returnDate == null ? '' : _date(returnDate!),
      adults,
      children,
      infants,
      cabinClass,
      tripType ??
          (journeyType == 1
              ? 'one-way'
              : journeyType == 2
              ? 'round-trip'
              : 'multi-city'),
      flightType,
      limit,
      segmentKey,
      normalizedAirlines.join(','),
      normalizeCurrency(currency),
    ].join('|');
  }

  List<String> get normalizedAirlines => preferredAirlines
      .map(normalizeAirlineCode)
      .where((code) => code != null)
      .cast<String>()
      .toList(growable: false);

  Map<String, dynamic> toJson() => {
    'JourneyType': journeyType,
    if (journeyType != 3) ...{
      'Origin': normalizeAirportCode(origin),
      'Destination': normalizeAirportCode(destination),
      'DepartureDate': _date(departure),
      'ReturnDate': returnDate == null ? null : _date(returnDate!),
    },
    'AdultCount': adults,
    'ChildCount': children,
    'InfantCount': infants,
    'FlightCabinClass': cabinClass,
    'PreferredAirlines': normalizedAirlines.isEmpty ? null : normalizedAirlines,
    'currency': normalizeCurrency(currency),
    'Currency': normalizeCurrency(currency),
    if (journeyType == 3)
      'Segments': segments
          .map((segment) => segment.toJson(cabinClass))
          .toList(),
    if (filters != null && filters!.toJson().isNotEmpty)
      'filters': filters!.toJson(),
    if (sort != null && sort!.isNotEmpty) ...{'sort': sort, 'Sort': sort},
    if (endUserIp != null && endUserIp!.isNotEmpty) 'EndUserIp': endUserIp,
  };

  Map<String, String> toQueryParameters() => {
    'from': normalizeAirportCode(origin),
    'to': normalizeAirportCode(destination),
    'depart': _date(departure),
    if (returnDate != null) 'return': _date(returnDate!),
    'trip':
        tripType ??
        (journeyType == 1
            ? 'one-way'
            : journeyType == 2
            ? 'round-trip'
            : 'multi-city'),
    if (segments.isNotEmpty)
      'segments': segments
          .map(
            (s) =>
                '${normalizeAirportCode(s.origin)}|${normalizeAirportCode(s.destination)}|${_date(s.departure)}',
          )
          .join(','),
    'adults': adults.toString(),
    'children': children.toString(),
    'infants': infants.toString(),
    'cabin': cabinClass.toString(),
    'currency': normalizeCurrency(currency),
    if (normalizedAirlines.isNotEmpty) 'airlines': normalizedAirlines.join(','),
    if (sort != null && sort!.isNotEmpty) 'sort': sort!,
    'flightType': flightType,
    'limit': limit.toString(),
    if (searchId != null && searchId!.isNotEmpty) 'search_id': searchId!,
  };

  static String normalizeAirportCode(String value) =>
      value.trim().toUpperCase();

  static String normalizeCurrency(String value) {
    final normalized = value.trim().toUpperCase();
    return RegExp(r'^[A-Z]{3}$').hasMatch(normalized) ? normalized : 'USD';
  }

  static String? normalizeAirlineCode(String value) {
    final normalized = value.trim().toUpperCase();
    return RegExp(r'^[A-Z0-9]{2,3}$').hasMatch(normalized) ? normalized : null;
  }

  static String _date(DateTime value) =>
      value.toIso8601String().split('T').first;
}

class FlightSearchSegment {
  const FlightSearchSegment({
    required this.origin,
    required this.destination,
    required this.departure,
    this.cabinClass,
  });

  final String origin;
  final String destination;
  final DateTime departure;
  final int? cabinClass;

  Map<String, dynamic> toJson(int fallbackCabinClass) => {
    'Origin': FlightSearch.normalizeAirportCode(origin),
    'Destination': FlightSearch.normalizeAirportCode(destination),
    'PreferredDepartureTime': FlightSearch._date(departure),
    'FlightCabinClass': cabinClass ?? fallbackCabinClass,
  };
}

class FlightSearchFilters {
  const FlightSearchFilters({
    this.airlines = const [],
    this.direct,
    this.oneStopOrLess = false,
    this.hasCheckedBaggage,
    this.minPrice,
    this.maxPrice,
  });

  final List<String> airlines;
  final bool? direct;
  final bool oneStopOrLess;
  final bool? hasCheckedBaggage;
  final num? minPrice;
  final num? maxPrice;

  Map<String, dynamic> toJson() {
    final normalizedAirlines = airlines
        .map(FlightSearch.normalizeAirlineCode)
        .where((code) => code != null)
        .cast<String>()
        .toList(growable: false);
    return {
      if (normalizedAirlines.isNotEmpty) ...{
        'airlines': normalizedAirlines,
        'marketing_airlines': normalizedAirlines,
      },
      if (direct == true) ...{
        'direct': true,
        'direct_flights': true,
        'stops': '0',
      } else if (oneStopOrLess)
        'stops': '0,1',
      if (hasCheckedBaggage == true) 'has_checked_baggage': true,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
    };
  }
}
