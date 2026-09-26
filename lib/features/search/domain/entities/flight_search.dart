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
    'cabinClass': cabinClass,
    'cabin_class': cabinClassString,
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
    'cabinClass': cabinClass.toString(),
    'cabin_class': cabinClass.toString(),
    'FlightCabinClass': cabinClass.toString(),
    'currency': normalizeCurrency(currency),
    if (normalizedAirlines.isNotEmpty) 'airlines': normalizedAirlines.join(','),
    if (sort != null && sort!.isNotEmpty) 'sort': sort!,
    'flightType': flightType,
    'limit': limit.toString(),
    if (searchId != null && searchId!.isNotEmpty) 'search_id': searchId!,
  };

  String get cabinClassString => resolveCabinString(cabinClass);

  static String resolveCabinString(int cabinClass) {
    switch (cabinClass) {
      case 1:
        return 'Economy';
      case 2:
        return 'Business';
      case 3:
        return 'First';
      case 4:
        return 'Premium Economy';
      default:
        return 'Economy';
    }
  }

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
    'cabinClass': cabinClass ?? fallbackCabinClass,
    'cabin_class': FlightSearch.resolveCabinString(cabinClass ?? fallbackCabinClass),
  };
}

class FlightSearchFilters {
  const FlightSearchFilters({
    this.airlines = const [],
    this.marketingAirlines = const [],
    this.operatingAirlines = const [],
    this.direct,
    this.oneStopOrLess = false,
    this.stops,
    this.cabinClass,
    this.departureTime,
    this.arrivalTime,
    this.refundable,
    this.minPrice,
    this.maxPrice,
    this.minDuration,
    this.maxDuration,
    this.minJourneyDuration,
    this.maxJourneyDuration,
    this.minLayover,
    this.maxLayover,
    this.minLayoverDuration,
    this.maxLayoverDuration,
    this.connectingAirports,
    this.originAirports,
    this.destinationAirports,
    this.hasCheckedBaggage,
    this.hasCarryOn,
    this.hasCabinBaggage,
    this.baggageUnit,
    this.minCheckedPcs,
    this.minCheckedKg,
    this.baggagePcs,
    this.baggageKg,
  });

  final List<String> airlines;
  final List<String> marketingAirlines;
  final List<String> operatingAirlines;
  final bool? direct;
  final bool oneStopOrLess;
  final String? stops;
  final String? cabinClass;
  final String? departureTime;
  final String? arrivalTime;
  final bool? refundable;
  final num? minPrice;
  final num? maxPrice;
  final int? minDuration;
  final int? maxDuration;
  final int? minJourneyDuration;
  final int? maxJourneyDuration;
  final int? minLayover;
  final int? maxLayover;
  final int? minLayoverDuration;
  final int? maxLayoverDuration;
  final String? connectingAirports;
  final String? originAirports;
  final String? destinationAirports;
  final bool? hasCheckedBaggage;
  final bool? hasCarryOn;
  final bool? hasCabinBaggage;
  final String? baggageUnit;
  final num? minCheckedPcs;
  final num? minCheckedKg;
  final num? baggagePcs;
  final num? baggageKg;

  Map<String, dynamic> toJson() {
    final normalizedAirlines = airlines
        .map(FlightSearch.normalizeAirlineCode)
        .where((code) => code != null)
        .cast<String>()
        .toList(growable: false);
    final normalizedMarketing = marketingAirlines
        .map(FlightSearch.normalizeAirlineCode)
        .where((code) => code != null)
        .cast<String>()
        .toList(growable: false);
    final normalizedOperating = operatingAirlines
        .map(FlightSearch.normalizeAirlineCode)
        .where((code) => code != null)
        .cast<String>()
        .toList(growable: false);

    return {
      if (normalizedAirlines.isNotEmpty) ...{
        'airlines': normalizedAirlines,
        'marketing_airlines': normalizedMarketing.isNotEmpty
            ? normalizedMarketing
            : normalizedAirlines,
        if (normalizedOperating.isNotEmpty)
          'operating_airlines': normalizedOperating,
      },
      if (direct == true) ...{
        'direct': true,
        'direct_flights': true,
        'stops': '0',
      } else if (stops != null && stops!.isNotEmpty)
        'stops': stops
      else if (oneStopOrLess)
        'stops': '0,1',
      if (cabinClass != null && cabinClass!.isNotEmpty)
        'cabin_class': cabinClass,
      if (departureTime != null && departureTime!.isNotEmpty)
        'departure_time': departureTime,
      if (arrivalTime != null && arrivalTime!.isNotEmpty)
        'arrival_time': arrivalTime,
      if (refundable != null) 'refundable': refundable,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (minDuration != null) 'min_duration': minDuration,
      if (maxDuration != null) 'max_duration': maxDuration,
      if (minJourneyDuration != null)
        'min_journey_duration': minJourneyDuration,
      if (maxJourneyDuration != null)
        'max_journey_duration': maxJourneyDuration,
      if (minLayover != null) 'min_layover': minLayover,
      if (maxLayover != null) 'max_layover': maxLayover,
      if (minLayoverDuration != null)
        'min_layover_duration': minLayoverDuration,
      if (maxLayoverDuration != null)
        'max_layover_duration': maxLayoverDuration,
      if (connectingAirports != null && connectingAirports!.isNotEmpty)
        'connecting_airports': connectingAirports,
      if (originAirports != null && originAirports!.isNotEmpty)
        'origin_airports': originAirports,
      if (destinationAirports != null && destinationAirports!.isNotEmpty)
        'destination_airports': destinationAirports,
      if (hasCheckedBaggage != null) 'has_checked_baggage': hasCheckedBaggage,
      if (hasCarryOn != null) 'has_carry_on': hasCarryOn,
      if (hasCabinBaggage != null) 'has_cabin_baggage': hasCabinBaggage,
      if (baggageUnit != null && baggageUnit!.isNotEmpty)
        'baggage_unit': baggageUnit,
      if (minCheckedPcs != null) 'min_checked_pcs': minCheckedPcs,
      if (minCheckedKg != null) 'min_checked_kg': minCheckedKg,
      if (baggagePcs != null) 'baggage_pcs': baggagePcs,
      if (baggageKg != null) 'baggage_kg': baggageKg,
    };
  }
}

String getCabinClassName(int cabinClass, bool isAr) {
  switch (cabinClass) {
    case 1:
      return isAr ? 'اقتصادية' : 'Economy';
    case 2:
      return isAr ? 'أعمال' : 'Business';
    case 3:
      return isAr ? 'الأولى' : 'First Class';
    case 4:
      return isAr ? 'اقتصادية مميزة' : 'Premium Economy';
    default:
      return isAr ? 'اقتصادية' : 'Economy';
  }
}

String resolveFlightCabinName({
  required String offerCabin,
  required int searchCabinClass,
  required bool isAr,
}) {
  final clean = offerCabin.trim().toLowerCase();
  final parsed = int.tryParse(clean);
  if (parsed != null && parsed > 0) {
    return getCabinClassName(parsed, isAr);
  }
  if (clean == 'economy' || clean == 'e') return isAr ? 'اقتصادية' : 'Economy';
  if (clean == 'business' || clean == 'b' || clean == 'c' || clean == 'j') {
    return isAr ? 'أعمال' : 'Business';
  }
  if (clean == 'first' || clean == 'f' || clean == 'first class') {
    return isAr ? 'الأولى' : 'First Class';
  }
  if (clean.contains('premium')) return isAr ? 'اقتصادية مميزة' : 'Premium Economy';
  if (clean.isNotEmpty) return offerCabin;
  return getCabinClassName(searchCabinClass, isAr);
}
