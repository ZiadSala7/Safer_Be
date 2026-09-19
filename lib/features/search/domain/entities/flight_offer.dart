import '../../../../core/network/json_read.dart';
import 'flight_search.dart';

class FlightOffer {
  const FlightOffer({
    required this.id,
    required this.airline,
    required this.route,
    required this.time,
    required this.price,
    required this.currency,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.stops,
    required this.cabinClass,
    required this.baggage,
    required this.refundable,
    required this.labels,
    this.airlineCode,
    this.resultIndex,
    this.referenceIndex,
    this.supplier,
    this.searchId,
    this.segments,
    this.rawJson,
    this.expiresIn,
    this.quotedAt,
  });

  final String id;
  final String airline;
  final String route;
  final String time;
  final num price;
  final String currency;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final int durationMinutes;
  final int stops;
  final String cabinClass;
  final String baggage;
  final bool refundable;
  final List<String> labels;
  final String? airlineCode;
  final String? resultIndex;
  final String? referenceIndex;
  final String? supplier;
  final String? searchId;
  final List<Map<String, dynamic>>? segments;
  final Map<String, dynamic>? rawJson;
  final int? expiresIn;
  final DateTime? quotedAt;

  bool get isQuoteExpired {
    if (expiresIn == null || quotedAt == null) return false;
    final expiresAt = quotedAt!.add(Duration(seconds: expiresIn!));
    return DateTime.now().isAfter(expiresAt);
  }

  int get remainingQuoteSeconds {
    if (expiresIn == null || quotedAt == null) return 0;
    final expiresAt = quotedAt!.add(Duration(seconds: expiresIn!));
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool get hasCheckedBaggage {
    final normalized = baggage.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized.contains('0 kg') || normalized.contains('0kg')) {
      return false;
    }
    return normalized.contains('checked') ||
        normalized.contains('kg') ||
        normalized.contains('piece') ||
        normalized.contains('pc');
  }

  String get origin {
    final parts = route.split('→');
    return parts.isNotEmpty ? parts.first.trim() : '';
  }

  String get destination {
    final parts = route.split('→');
    return parts.length > 1 ? parts[1].trim() : '';
  }

  FlightOffer copyWith({
    String? id,
    String? airline,
    String? route,
    String? time,
    num? price,
    String? currency,
    DateTime? departureTime,
    DateTime? arrivalTime,
    int? durationMinutes,
    int? stops,
    String? cabinClass,
    String? baggage,
    bool? refundable,
    List<String>? labels,
    String? airlineCode,
    String? resultIndex,
    String? referenceIndex,
    String? supplier,
    String? searchId,
    List<Map<String, dynamic>>? segments,
    Map<String, dynamic>? rawJson,
    int? expiresIn,
    DateTime? quotedAt,
  }) => FlightOffer(
    id: id ?? this.id,
    airline: airline ?? this.airline,
    route: route ?? this.route,
    time: time ?? this.time,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    departureTime: departureTime ?? this.departureTime,
    arrivalTime: arrivalTime ?? this.arrivalTime,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    stops: stops ?? this.stops,
    cabinClass: cabinClass ?? this.cabinClass,
    baggage: baggage ?? this.baggage,
    refundable: refundable ?? this.refundable,
    labels: labels ?? this.labels,
    airlineCode: airlineCode ?? this.airlineCode,
    resultIndex: resultIndex ?? this.resultIndex,
    referenceIndex: referenceIndex ?? this.referenceIndex,
    supplier: supplier ?? this.supplier,
    searchId: searchId ?? this.searchId,
    segments: segments ?? this.segments,
    rawJson: rawJson ?? this.rawJson,
    expiresIn: expiresIn ?? this.expiresIn,
    quotedAt: quotedAt ?? this.quotedAt,
  );

  factory FlightOffer.fromJson(Map<String, dynamic> json) {
    final legs = json['legs'] is List
        ? json['legs'] as List
        : json['segments'] is List
        ? json['segments'] as List
        : const [];
    final first = legs.isNotEmpty && legs.first is Map
        ? legs.first as Map
        : json;
    final last = legs.isNotEmpty && legs.last is Map ? legs.last as Map : first;
    final origin = first['origin'] is Map ? first['origin'] as Map : const {};
    final destination = last['destination'] is Map
        ? last['destination'] as Map
        : const {};
    final from = readText(origin, [
      'code',
    ], readText(first, ['origin_code', 'origin']));
    final to = readText(destination, [
      'code',
    ], readText(last, ['destination_code', 'destination']));
    final price = json['price'] is Map ? json['price'] as Map : json;
    final departure = readText(first, [
      'departure_time',
      'departureTime',
      'DepartureTime',
      'departure',
    ]);
    final arrival = readText(last, [
      'arrival_time',
      'arrivalTime',
      'ArrivalTime',
      'arrival',
    ]);
    final baggage = json['baggage'] is Map ? json['baggage'] as Map : const {};
    final labels = json['best_deal_labels'] is List
        ? (json['best_deal_labels'] as List)
              .map((item) => item.toString())
              .toList(growable: false)
        : const <String>[];
    final parsedSegments = legs
        .whereType<Map>()
        .map((leg) => Map<String, dynamic>.from(leg))
        .toList(growable: false);

    final airlineCode = readText(
      json,
      [
        'airlineCode',
        'airline_code',
        'marketing_airline',
        'validating_airline',
      ],
      readText(first, [
        'airlineCode',
        'airline_code',
        'airline',
        'marketing_airline',
      ]),
    );
    final stopsCount = readNumber(first, ['stops_count', 'stops']).toInt();

    return FlightOffer(
      id: readText(json, ['id', 'resultIndex', 'result_index']),
      resultIndex: _readNullableText(json, ['resultIndex', 'result_index']),
      referenceIndex: _readNullableText(json, [
        'reference_index',
        'referenceIndex',
      ]),
      supplier: readText(json, ['supplier'], 'tbo'),
      searchId: _readNullableText(json, ['search_id', 'searchId']),
      airlineCode: airlineCode.isEmpty ? null : airlineCode,
      airline: readText(
        json,
        ['airlineName', 'airline_name'],
        readText(first, [
          'airlineName',
          'airline_name',
          'airlineCode',
          'airline_code',
        ], 'Airline'),
      ),
      route: '$from → $to',
      time: departure.isEmpty ? 'Scheduled flight' : departure,
      price: readNumber(price, [
        'total',
        'totalPrice',
        'total_price',
        'publishedFare',
        'price',
      ]),
      currency: readText(price, ['currency', 'currency_code'], 'USD'),
      departureTime: DateTime.tryParse(departure),
      arrivalTime: DateTime.tryParse(arrival),
      durationMinutes: legs.fold<int>(
        0,
        (total, leg) =>
            total +
            (leg is Map
                ? readNumber(leg, [
                    'duration_minutes',
                    'durationMinutes',
                  ]).toInt()
                : 0),
      ),
      stops: legs.isEmpty
          ? stopsCount
          : stopsCount > 0
          ? stopsCount
          : legs.length - 1,
      cabinClass: readText(first, ['cabin_class', 'cabinClass', 'CabinClass']),
      baggage: readText(baggage, ['description', 'checked', 'carry_on']),
      refundable: json['refundable'] == true || json['isRefundable'] == true,
      labels: labels,
      segments: parsedSegments.isNotEmpty ? parsedSegments : null,
      rawJson: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toFlightDataMap(FlightSearch search) {
    final map = Map<String, dynamic>.from(rawJson ?? {});
    final resIndex = resultIndex ?? id;
    map['resultIndex'] = resIndex;
    map['result_index'] = resIndex;
    if (referenceIndex != null && referenceIndex!.isNotEmpty) {
      map['reference_index'] = referenceIndex;
    }
    if (searchId != null && searchId!.isNotEmpty) {
      map['search_id'] = searchId;
    }
    final code =
        airlineCode ?? map['airlineCode'] ?? map['airline_code'] ?? 'MS';
    map['airlineCode'] = code;
    map['airlineName'] = airline;
    map['totalPrice'] = price;
    map['currency'] = currency;
    map['isRefundable'] = refundable;

    List<dynamic> segs = [];
    if (map['segments'] is List && (map['segments'] as List).isNotEmpty) {
      segs = map['segments'] as List;
    } else if (map['legs'] is List && (map['legs'] as List).isNotEmpty) {
      segs = map['legs'] as List;
    }

    final formattedSegments = <Map<String, dynamic>>[];
    if (segs.isNotEmpty) {
      for (final seg in segs) {
        if (seg is Map) {
          final originMap = seg['origin'] is Map
              ? seg['origin'] as Map
              : {
                  'code': search.origin,
                  'name': search.origin,
                  'city': search.origin,
                  'country': 'EG',
                };
          final destMap = seg['destination'] is Map
              ? seg['destination'] as Map
              : {
                  'code': search.destination,
                  'name': search.destination,
                  'city': search.destination,
                  'country': 'AE',
                };
          formattedSegments.add({
            'origin': {
              'code': readText(originMap, ['code'], search.origin),
              'name': readText(originMap, ['name'], search.origin),
              'city': readText(originMap, ['city'], search.origin),
              'country': readText(originMap, ['country'], 'EG'),
            },
            'destination': {
              'code': readText(destMap, ['code'], search.destination),
              'name': readText(destMap, ['name'], search.destination),
              'city': readText(destMap, ['city'], search.destination),
              'country': readText(destMap, ['country'], 'AE'),
            },
            'airlineCode': readText(seg, [
              'airlineCode',
              'airline_code',
              'airline',
            ], code),
            'airlineName': readText(seg, [
              'airlineName',
              'airline_name',
            ], airline),
            'flightNumber': readText(seg, [
              'flightNumber',
              'flight_number',
            ], '101'),
            'departureTime': readText(seg, [
              'departureTime',
              'departure_time',
            ], search.departure.toIso8601String()),
            'arrivalTime': readText(
              seg,
              ['arrivalTime', 'arrival_time'],
              search.departure.add(const Duration(hours: 4)).toIso8601String(),
            ),
            'duration':
                readNumber(seg, ['duration', 'duration_minutes']).toInt() > 0
                ? readNumber(seg, ['duration', 'duration_minutes']).toInt()
                : 240,
            'cabinClass':
                readNumber(seg, ['cabinClass', 'cabin_class']).toInt() > 0
                ? readNumber(seg, ['cabinClass', 'cabin_class']).toInt()
                : 1,
            'baggage': readText(seg, [
              'baggage',
            ], baggage.isNotEmpty ? baggage : '23KG'),
          });
        }
      }
    }

    if (formattedSegments.isEmpty) {
      formattedSegments.add({
        'origin': {
          'code': search.origin,
          'name': search.origin,
          'city': search.origin,
          'country': 'EG',
        },
        'destination': {
          'code': search.destination,
          'name': search.destination,
          'city': search.destination,
          'country': 'AE',
        },
        'airlineCode': code,
        'airlineName': airline,
        'flightNumber': '101',
        'departureTime': search.departure.toIso8601String(),
        'arrivalTime': search.departure
            .add(const Duration(hours: 4))
            .toIso8601String(),
        'duration': durationMinutes > 0 ? durationMinutes : 240,
        'cabinClass': 1,
        'baggage': baggage.isNotEmpty ? baggage : '23KG',
      });
    }

    map['segments'] = formattedSegments;
    return map;
  }

  static String? _readNullableText(Map data, List<String> keys) {
    final value = readText(data, keys);
    return value.isEmpty ? null : value;
  }
}
