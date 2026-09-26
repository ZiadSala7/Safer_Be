import '../entities/flight_offer.dart';
import '../entities/hotel_offer.dart';
import '../../presentation/widgets/flight_filter_sheet.dart';
import '../../presentation/widgets/hotel_filter_sheet.dart';

/// Utility to normalize text for search across Arabic and English.
String normalizeTravelText(String text) {
  if (text.isEmpty) return '';
  var normalized = text.toLowerCase().trim();

  // Remove Arabic diacritics (tashkeel)
  normalized = normalized.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

  // Normalize Arabic letters
  normalized = normalized
      .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'ء')
      .replaceAll('ئ', 'ء')
      .replaceAll('ك', 'ك')
      .replaceAll('گ', 'ك')
      .replaceAll('ي', 'ي')
      .replaceAll('ی', 'ي');

  return normalized;
}

String _stripKeywords(
  String text,
  List<String> keywords, {
  required void Function() onMatch,
}) {
  final allKeywords = <String>{};
  for (final kw in keywords) {
    final norm = normalizeTravelText(kw);
    if (norm.isEmpty) continue;
    allKeywords.add(norm);
    if (!norm.startsWith('ال')) {
      allKeywords.add('ال$norm');
    }
  }
  final sorted = allKeywords.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final kw in sorted) {
    if (text.contains(kw)) {
      onMatch();
      text = text.replaceAll(kw, ' ');
    }
  }
  return text;
}

/// Known airline aliases for smart natural language matching.
class _AirlineDef {
  const _AirlineDef(this.code, this.aliases);
  final String code;
  final List<String> aliases;
}

const List<_AirlineDef> _knownAirlines = [
  _AirlineDef('SV', [
    'saudi arabian airlines',
    'الخطوط السعوديه',
    'طيران السعوديه',
    'السعوديه',
    'saudia',
    'saudi',
  ]),
  _AirlineDef('XY', [
    'طيران الناصر',
    'طيران ناس',
    'flynas',
    'ناس',
    'nas',
  ]),
  _AirlineDef('F3', [
    'طيران عاديل',
    'طيران اديل',
    'flyadeal',
    'اديل',
    'adeal',
  ]),
  _AirlineDef('MS', [
    'مصر للطيران',
    'egypt air',
    'egyptair',
    'المصريه',
  ]),
  _AirlineDef('EK', [
    'طيران الامارات',
    'الامارات',
    'emirates',
    'امارات',
  ]),
  _AirlineDef('QR', [
    'الخطوط القطريه',
    'qatar airways',
    'طيران قطر',
    'القطريه',
    'qatar',
  ]),
  _AirlineDef('G9', [
    'العربيه للطيران',
    'air arabia',
    'العربيه',
  ]),
  _AirlineDef('FZ', [
    'طيران دبي',
    'فلاي دبي',
    'flydubai',
  ]),
  _AirlineDef('EY', [
    'etihad airways',
    'طيران الاتحاد',
    'الاتحاد',
    'etihad',
  ]),
  _AirlineDef('TK', [
    'turkish airlines',
    'الخطوط التركيه',
    'التركيه',
    'turkish',
  ]),
  _AirlineDef('GF', [
    'طيران الخليج',
    'gulf air',
    'الخليج',
  ]),
  _AirlineDef('KU', [
    'الخطوط الكويتيه',
    'kuwait airways',
    'الكويتيه',
  ]),
  _AirlineDef('RJ', [
    'الملكيه الاردنيه',
    'royal jordanian',
    'الاردنيه',
  ]),
  _AirlineDef('WY', [
    'الطيران العماني',
    'عمان اير',
    'oman air',
  ]),
  _AirlineDef('W6', [
    'wizz air',
    'ويز اير',
    'wizz',
    'ويز',
  ]),
  _AirlineDef('LH', [
    'lufthansa',
    'لوفتهانزا',
  ]),
  _AirlineDef('BA', [
    'الخطوط البريطانيه',
    'british airways',
    'البريطانيه',
  ]),
  _AirlineDef('AF', [
    'الخطوط الفرنسيه',
    'air france',
  ]),
];

/// Smart Flight Search Query Parser and Intent Extractor
class FlightSearchIntent {
  FlightSearchIntent({
    this.directOnly = false,
    this.transitOnly = false,
    this.withBaggage = false,
    this.refundable = false,
    this.morning = false,
    this.evening = false,
    this.afternoon = false,
    this.maxPrice,
    this.sortByCheapest = false,
    this.sortByShortest = false,
    this.targetAirlineCodes = const {},
    this.targetAirlineKeywords = const [],
    this.remainingTokens = const [],
  });

  final bool directOnly;
  final bool transitOnly;
  final bool withBaggage;
  final bool refundable;
  final bool morning;
  final bool evening;
  final bool afternoon;
  final double? maxPrice;
  final bool sortByCheapest;
  final bool sortByShortest;
  final Set<String> targetAirlineCodes;
  final List<String> targetAirlineKeywords;
  final List<String> remainingTokens;

  bool get hasAnyFilter =>
      directOnly ||
      transitOnly ||
      withBaggage ||
      refundable ||
      morning ||
      evening ||
      afternoon ||
      maxPrice != null ||
      sortByCheapest ||
      sortByShortest ||
      targetAirlineCodes.isNotEmpty ||
      targetAirlineKeywords.isNotEmpty ||
      remainingTokens.isNotEmpty;

  factory FlightSearchIntent.fromQuery(String rawQuery) {
    var text = normalizeTravelText(rawQuery);
    if (text.isEmpty) return FlightSearchIntent();

    bool directOnly = false;
    bool transitOnly = false;
    bool withBaggage = false;
    bool refundable = false;
    bool morning = false;
    bool evening = false;
    bool afternoon = false;
    double? maxPrice;
    bool sortByCheapest = false;
    bool sortByShortest = false;
    final Set<String> targetAirlineCodes = {};
    final List<String> targetAirlineKeywords = [];

    // 1. Direct / Non-stop
    text = _stripKeywords(
      text,
      [
        'بدون توقف',
        'رحلات مباشره',
        'رحلة مباشرة',
        'مباشره',
        'مباشر',
        'دايركت',
        'non-stop',
        'nonstop',
        'direct flights',
        'direct flight',
        'direct',
      ],
      onMatch: () => directOnly = true,
    );

    // Transit
    text = _stripKeywords(
      text,
      [
        'غير مباشر',
        'توقف واحد',
        'ترانزيت',
        'توقف',
        'transit',
        '1 stop',
        'one stop',
        'stop',
      ],
      onMatch: () => transitOnly = true,
    );

    // 2. Baggage
    text = _stripKeywords(
      text,
      [
        'شامل الحقائب',
        'شامل الامتعه',
        'شامل العفش',
        'مع حقيبه',
        'مع امتعه',
        'مع شنطه',
        'مع شنط',
        'حقائب',
        'حقيبه',
        'امتعه',
        'شنطه',
        'شنط',
        'عفش',
        'وزن',
        'with checked baggage',
        'checked baggage',
        'baggage',
        'luggage',
        'bag',
        'checked',
      ],
      onMatch: () => withBaggage = true,
    );

    // 3. Refundable
    text = _stripKeywords(
      text,
      [
        'قابله للاسترداد',
        'تذاكر مسترده',
        'مسترده',
        'مسترد',
        'استرجاع',
        'مرنه',
        'مرن',
        'الغاء',
        'refundable tickets',
        'refundable',
      ],
      onMatch: () => refundable = true,
    );

    // 4. Departure Time slots
    text = _stripKeywords(
      text,
      [
        'رحلات صباحيه',
        'رحلات صباحي',
        'رحلة صباحية',
        'صباحيه',
        'صباحي',
        'صباح',
        'فجر',
        'بدري',
        'بكور',
        'morning flights',
        'morning flight',
        'morning',
        'early',
      ],
      onMatch: () => morning = true,
    );

    text = _stripKeywords(
      text,
      [
        'رحلات مسائيه',
        'رحلات مسائي',
        'رحلة مسائية',
        'مسائيه',
        'مسائي',
        'مساء',
        'ليلي',
        'ليل',
        'evening flights',
        'evening flight',
        'night flights',
        'evening',
        'night',
      ],
      onMatch: () => evening = true,
    );

    text = _stripKeywords(
      text,
      [
        'عصريه',
        'ظهيره',
        'عصر',
        'ظهر',
        'afternoon',
      ],
      onMatch: () => afternoon = true,
    );

    // 5. Price intent
    text = _stripKeywords(
      text,
      [
        'ارخص الرحلات',
        'افضل سعر',
        'اقل سعر',
        'اقتصاديه',
        'اقتصادي',
        'رخيصه',
        'ارخص',
        'رخيص',
        'cheapest flights',
        'cheapest flight',
        'lowest price',
        'best price',
        'cheapest',
        'cheap',
        'budget',
      ],
      onMatch: () => sortByCheapest = true,
    );

    text = _stripKeywords(
      text,
      [
        'اسرع الرحلات',
        'اقصر',
        'اسرع',
        'fastest',
        'shortest',
        'quickest',
      ],
      onMatch: () => sortByShortest = true,
    );

    // Extract price number if explicitly given e.g. "أقل من 500" or "< 500" or "under 600"
    final priceMatch = RegExp(r'(?:اقل من|تحت|سعر|max|under|<|less than)\s*(\d+)|(?:\b(\d{3,5})\b)').firstMatch(text);
    if (priceMatch != null) {
      final numStr = priceMatch.group(1) ?? priceMatch.group(2);
      if (numStr != null) {
        final parsed = double.tryParse(numStr);
        if (parsed != null && parsed >= 50 && parsed <= 50000) {
          maxPrice = parsed;
          text = text.replaceFirst(priceMatch.group(0)!, ' ');
        }
      }
    }

    // 6. Airline matching
    for (final airline in _knownAirlines) {
      final sortedAliases = List<String>.of(airline.aliases)
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final alias in sortedAliases) {
        final normAlias = normalizeTravelText(alias);
        if (text.contains(normAlias)) {
          targetAirlineCodes.add(airline.code);
          targetAirlineKeywords.add(normAlias);
          text = text.replaceAll(normAlias, ' ');
        }
      }
      if (text.contains(airline.code.toLowerCase())) {
        targetAirlineCodes.add(airline.code);
        text = text.replaceAll(airline.code.toLowerCase(), ' ');
      }
    }

    // Remove filler stop words in Arabic / English
    const stopWords = {
      'ال',
      'مع',
      'في',
      'الي',
      'من',
      'علي',
      'عن',
      'او',
      'رحلات',
      'الرحلات',
      'رحلة',
      'الرحلة',
      'رحلت',
      'الرحلت',
      'طيران',
      'الطيران',
      'خطوط',
      'الخطوط',
      'تذاكر',
      'التذاكر',
      'تذكرة',
      'التذكرة',
      'with',
      'to',
      'from',
      'for',
      'in',
      'flights',
      'flight',
      'airline',
      'airlines',
      'tickets',
      'ticket',
    };

    final tokens = text
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && t.length > 1 && !stopWords.contains(t))
        .map((t) => t.startsWith('ال') && t.length > 3 ? t.substring(2) : t)
        .where((t) => !stopWords.contains(t) && t.length > 1)
        .toList();

    return FlightSearchIntent(
      directOnly: directOnly,
      transitOnly: transitOnly,
      withBaggage: withBaggage,
      refundable: refundable,
      morning: morning,
      evening: evening,
      afternoon: afternoon,
      maxPrice: maxPrice,
      sortByCheapest: sortByCheapest,
      sortByShortest: sortByShortest,
      targetAirlineCodes: targetAirlineCodes,
      targetAirlineKeywords: targetAirlineKeywords,
      remainingTokens: tokens,
    );
  }

  bool matches(FlightOffer offer) {
    if (directOnly && offer.stops > 0) return false;
    if (transitOnly && offer.stops == 0) return false;
    if (withBaggage && !offer.hasCheckedBaggage) return false;
    if (refundable && !offer.refundable) return false;

    if (maxPrice != null && offer.price > maxPrice!) return false;

    // Time matching
    if (offer.departureTime != null) {
      final hour = offer.departureTime!.hour;
      if (morning && (hour < 4 || hour >= 12)) return false;
      if (afternoon && (hour < 12 || hour >= 18)) return false;
      if (evening && (hour < 18 && hour >= 4)) return false;
    }

    // Airline matching
    if (targetAirlineCodes.isNotEmpty) {
      final codeMatch = targetAirlineCodes.any(
        (c) =>
            offer.airlineCode?.toUpperCase() == c ||
            offer.airline.toUpperCase().contains(c),
      );
      final keywordMatch = targetAirlineKeywords.any((k) {
        final norm = normalizeTravelText(offer.airline);
        return norm.contains(k);
      });
      if (!codeMatch && !keywordMatch) return false;
    }

    // Remaining tokens match across offer fields (route, airline, time, flight number, baggage, labels)
    if (remainingTokens.isNotEmpty) {
      final searchableContent = normalizeTravelText([
        offer.airline,
        offer.airlineCode ?? '',
        offer.route,
        offer.time,
        offer.cabinClass,
        offer.baggage,
        ...offer.labels,
        if (offer.segments != null)
          ...offer.segments!.map(
            (s) => '${s['airlineName'] ?? ''} ${s['flightNumber'] ?? ''} ${s['origin']?['city'] ?? ''} ${s['destination']?['city'] ?? ''}',
          ),
      ].join(' '));

      final allTokensFound = remainingTokens.every(
        (token) => searchableContent.contains(token),
      );
      if (!allTokensFound) return false;
    }

    return true;
  }
}

/// Smart Hotel Search Query Parser and Intent Extractor
class HotelSearchIntent {
  HotelSearchIntent({
    this.minRating,
    this.requiredAmenities = const [],
    this.freeCancellation = false,
    this.maxPrice,
    this.sortByCheapest = false,
    this.sortByHighestRated = false,
    this.remainingTokens = const [],
  });

  final int? minRating;
  final List<String> requiredAmenities;
  final bool freeCancellation;
  final double? maxPrice;
  final bool sortByCheapest;
  final bool sortByHighestRated;
  final List<String> remainingTokens;

  bool get hasAnyFilter =>
      minRating != null ||
      requiredAmenities.isNotEmpty ||
      freeCancellation ||
      maxPrice != null ||
      sortByCheapest ||
      sortByHighestRated ||
      remainingTokens.isNotEmpty;

  factory HotelSearchIntent.fromQuery(String rawQuery) {
    var text = normalizeTravelText(rawQuery);
    if (text.isEmpty) return HotelSearchIntent();

    int? minRating;
    final List<String> requiredAmenities = [];
    bool freeCancellation = false;
    double? maxPrice;
    bool sortByCheapest = false;
    bool sortByHighestRated = false;

    // 1. Star ratings
    text = _stripKeywords(
      text,
      [
        'فنادق 5 نجوم',
        'فندق 5 نجوم',
        'خمس نجوم',
        '5 نجوم',
        '5 stars',
        '5-star',
        '5*',
        'فاخرة',
        'فاخر',
        'luxury',
      ],
      onMatch: () => minRating = 5,
    );

    if (minRating == null) {
      text = _stripKeywords(
        text,
        [
          'فنادق 4 نجوم',
          'فندق 4 نجوم',
          'اربع نجوم',
          '4 نجوم',
          '4 stars',
          '4-star',
          '4*',
        ],
        onMatch: () => minRating = 4,
      );
    }

    if (minRating == null) {
      text = _stripKeywords(
        text,
        [
          'فنادق 3 نجوم',
          'فندق 3 نجوم',
          'ثلاث نجوم',
          '3 نجوم',
          '3 stars',
          '3-star',
          '3*',
        ],
        onMatch: () => minRating = 3,
      );
    }

    // 2. Amenities
    text = _stripKeywords(
      text,
      [
        'حمام سباحه',
        'swimming pool',
        'مسبح',
        'pool',
      ],
      onMatch: () => requiredAmenities.add('pool'),
    );

    text = _stripKeywords(
      text,
      [
        'breakfast included',
        'breakfast buffet',
        'شامل الافطار',
        'شامل الفطور',
        'مع افطار',
        'مع فطور',
        'افطار',
        'فطور',
        'ريوق',
        'breakfast',
        'buffet',
      ],
      onMatch: () => requiredAmenities.add('breakfast'),
    );

    text = _stripKeywords(
      text,
      [
        'واي فاي مجاني',
        'free wifi',
        'واي فاي',
        'انترنت',
        'wi-fi',
        'wifi',
        'نت',
      ],
      onMatch: () => requiredAmenities.add('wifi'),
    );

    text = _stripKeywords(
      text,
      [
        'fitness center',
        'fitness',
        'رياضه',
        'لياقه',
        'جيم',
        'gym',
      ],
      onMatch: () => requiredAmenities.add('gym'),
    );

    text = _stripKeywords(
      text,
      [
        'free parking',
        'مواقف مجانيه',
        'باركنج',
        'مواقف',
        'موقف',
        'parking',
      ],
      onMatch: () => requiredAmenities.add('parking'),
    );

    text = _stripKeywords(
      text,
      [
        'جاكوزي',
        'سونا',
        'سبا',
        'jacuzzi',
        'sauna',
        'spa',
      ],
      onMatch: () => requiredAmenities.add('spa'),
    );

    text = _stripKeywords(
      text,
      [
        'مطل علي البحر',
        'sea view',
        'شاطئ',
        'beach',
        'بحر',
      ],
      onMatch: () => requiredAmenities.add('beach'),
    );

    // 3. Free Cancellation
    text = _stripKeywords(
      text,
      [
        'الغاء مجاني',
        'استرداد مجاني',
        'free cancellation',
        'refundable',
        'مرن',
      ],
      onMatch: () => freeCancellation = true,
    );

    // 4. Sort and Price
    text = _stripKeywords(
      text,
      [
        'ارخص الفنادق',
        'افضل سعر',
        'اقل سعر',
        'اقتصاديه',
        'اقتصادي',
        'رخيصه',
        'ارخص',
        'رخيص',
        'lowest price',
        'best price',
        'cheapest',
        'cheap',
      ],
      onMatch: () => sortByCheapest = true,
    );

    text = _stripKeywords(
      text,
      [
        'الاعلي تقييما',
        'اعلي تقييم',
        'افضل تقييم',
        'highest rated',
        'top rated',
        'best rated',
        'ممتاز',
      ],
      onMatch: () => sortByHighestRated = true,
    );

    final priceMatch = RegExp(r'(?:اقل من|تحت|سعر|max|under|<|less than)\s*(\d+)|(?:\b(\d{3,5})\b)').firstMatch(text);
    if (priceMatch != null) {
      final numStr = priceMatch.group(1) ?? priceMatch.group(2);
      if (numStr != null) {
        final parsed = double.tryParse(numStr);
        if (parsed != null && parsed >= 50 && parsed <= 50000) {
          maxPrice = parsed;
          text = text.replaceFirst(priceMatch.group(0)!, ' ');
        }
      }
    }

    const hotelStopWords = {
      'ال',
      'مع',
      'في',
      'الي',
      'من',
      'علي',
      'عن',
      'او',
      'فندق',
      'الفندق',
      'فنادق',
      'الفنادق',
      'شقق',
      'الشقق',
      'منتجع',
      'المنتجع',
      'اقامه',
      'الاقامه',
      'حجز',
      'الحجز',
      'with',
      'to',
      'from',
      'for',
      'in',
      'hotel',
      'hotels',
      'stay',
      'resort',
      'suites',
    };

    final tokens = text
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && t.length > 1 && !hotelStopWords.contains(t))
        .map((t) => t.startsWith('ال') && t.length > 3 ? t.substring(2) : t)
        .where((t) => !hotelStopWords.contains(t) && t.length > 1)
        .toList();

    return HotelSearchIntent(
      minRating: minRating,
      requiredAmenities: requiredAmenities,
      freeCancellation: freeCancellation,
      maxPrice: maxPrice,
      sortByCheapest: sortByCheapest,
      sortByHighestRated: sortByHighestRated,
      remainingTokens: tokens,
    );
  }

  bool matches(HotelOffer offer) {
    if (minRating != null && offer.rating < minRating!) return false;
    if (maxPrice != null && offer.price > maxPrice!) return false;

    final amenitiesBlob = normalizeTravelText(
      [...offer.amenities, offer.description].join(' '),
    );

    for (final amenity in requiredAmenities) {
      switch (amenity) {
        case 'pool':
          if (!amenitiesBlob.contains('pool') &&
              !amenitiesBlob.contains('مسبح') &&
              !amenitiesBlob.contains('سباح')) {
            return false;
          }
        case 'breakfast':
          if (!amenitiesBlob.contains('breakfast') &&
              !amenitiesBlob.contains('افطار') &&
              !amenitiesBlob.contains('فطور')) {
            return false;
          }
        case 'wifi':
          if (!amenitiesBlob.contains('wifi') &&
              !amenitiesBlob.contains('wi-fi') &&
              !amenitiesBlob.contains('انترنت') &&
              !amenitiesBlob.contains('واي فاي')) {
            return false;
          }
        case 'gym':
          if (!amenitiesBlob.contains('gym') &&
              !amenitiesBlob.contains('fitness') &&
              !amenitiesBlob.contains('جيم') &&
              !amenitiesBlob.contains('رياض')) {
            return false;
          }
        case 'parking':
          if (!amenitiesBlob.contains('park') &&
              !amenitiesBlob.contains('موقف') &&
              !amenitiesBlob.contains('كراج')) {
            return false;
          }
        case 'spa':
          if (!amenitiesBlob.contains('spa') &&
              !amenitiesBlob.contains('سبا') &&
              !amenitiesBlob.contains('جاكوزي') &&
              !amenitiesBlob.contains('sauna')) {
            return false;
          }
        case 'beach':
          if (!amenitiesBlob.contains('beach') &&
              !amenitiesBlob.contains('شاطئ') &&
              !amenitiesBlob.contains('بحر')) {
            return false;
          }
      }
    }

    if (freeCancellation) {
      final isFree = amenitiesBlob.contains('free cancel') ||
          amenitiesBlob.contains('الغاء مجاني') ||
          amenitiesBlob.contains('refundable') ||
          amenitiesBlob.contains('استرداد');
      if (!isFree) return false;
    }

    if (remainingTokens.isNotEmpty) {
      final searchableContent = normalizeTravelText(
        [
          offer.name,
          offer.location,
          offer.description,
          offer.supplier,
          ...offer.amenities,
        ].join(' '),
      );

      final allTokensFound = remainingTokens.every(
        (token) => searchableContent.contains(token),
      );
      if (!allTokensFound) return false;
    }

    return true;
  }
}

/// Unified Travel Search Engine
class TravelSearchEngine {
  /// Filters flights using structured filter state and intelligent natural language query.
  static List<FlightOffer> filterFlights({
    required List<FlightOffer> offers,
    required FlightFilterState filters,
    String query = '',
  }) {
    // 1. Apply user's structured filters first
    var result = filters.apply(offers);
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return result;

    // 2. Parse AI natural language intent and filter
    final intent = FlightSearchIntent.fromQuery(cleanQuery);
    result = result.where((offer) => intent.matches(offer)).toList();

    // 3. Dynamic sorting if specified by user's search text
    if (intent.sortByCheapest && filters.sort == FlightSortMode.best) {
      result.sort((a, b) => a.price.compareTo(b.price));
    } else if (intent.sortByShortest && filters.sort == FlightSortMode.best) {
      result.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    }

    return result;
  }

  /// Filters hotels using structured filter state and intelligent natural language query.
  static List<HotelOffer> filterHotels({
    required List<HotelOffer> offers,
    required HotelFilterState filters,
    String query = '',
  }) {
    // 1. Apply structured filters
    var result = filters.apply(offers);
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return result;

    // 2. Parse AI natural language intent and filter
    final intent = HotelSearchIntent.fromQuery(cleanQuery);
    result = result.where((offer) => intent.matches(offer)).toList();

    // 3. Dynamic sorting
    if (intent.sortByCheapest && filters.sort == HotelSortMode.best) {
      result.sort((a, b) => a.price.compareTo(b.price));
    } else if (intent.sortByHighestRated && filters.sort == HotelSortMode.best) {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return result;
  }
}
