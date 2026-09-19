import '../../../home/domain/entities/travel_content.dart';
import '../../../search/domain/entities/airport.dart';
import '../../../search/domain/entities/travel_city.dart';

enum OfferBookingType { hotel, flight }

class OfferPrefillData {
  const OfferPrefillData({
    required this.bookingType,
    required this.city,
    required this.destinationAirport,
    required this.originAirport,
    required this.promoCode,
    this.hotelName,
    this.displayName,
  });

  final OfferBookingType bookingType;
  final TravelCity city;
  final Airport destinationAirport;
  final Airport originAirport;
  final String promoCode;
  final String? hotelName;
  final String? displayName;
}

class OfferDestinationResolver {
  const OfferDestinationResolver._();

  static const TravelCity defaultCity = TravelCity(
    code: '113116',
    name: 'Jeddah',
    country: 'Saudi Arabia',
  );

  static const Airport defaultOrigin = Airport(
    code: 'RUH',
    name: 'King Khalid International Airport',
    city: 'Riyadh',
  );

  static const Airport defaultDestination = Airport(
    code: 'CAI',
    name: 'Cairo International Airport',
    city: 'Cairo',
  );

  /// Resolves the destination city, airport, and booking category from a [TravelOffer].
  static OfferPrefillData resolve(TravelOffer offer) {
    final cat = offer.category.trim().toLowerCase();
    final title = '${offer.titleKey} ${offer.title}'.toLowerCase();
    final subtitle = '${offer.subtitleKey} ${offer.description}'.toLowerCase();
    final fullText = '$title $subtitle';

    // 1. Detect Booking Category (Hotel vs Flight)
    var isFlight = cat == 'flights' || cat == 'flight';
    if (!isFlight &&
        (fullText.contains('flight') ||
            fullText.contains('طيران') ||
            fullText.contains('رحلات') ||
            fullText.contains('تذكرة طيران'))) {
      isFlight = true;
    }
    // If explicit hotel mention, hotel takes precedence unless category is flights
    if (cat != 'flights' &&
        (fullText.contains('فندق') ||
            fullText.contains('فنادق') ||
            fullText.contains('hotel') ||
            fullText.contains('stay') ||
            cat == 'hotels' ||
            cat == 'hotel')) {
      isFlight = false;
    }

    final bookingType =
        isFlight ? OfferBookingType.flight : OfferBookingType.hotel;

    // 2. Check offer conditions first
    for (final condition in offer.conditions) {
      final cType = condition.conditionType.toLowerCase();
      final cVal = condition.conditionValue.trim();
      if (cVal.isEmpty) continue;

      if (cType.contains('dest') ||
          cType.contains('city') ||
          cType.contains('hotel') ||
          cType.contains('location')) {
        final match = _matchCityAndAirport(cVal);
        if (match != null) {
          return OfferPrefillData(
            bookingType: bookingType,
            city: match.$1,
            destinationAirport: match.$2,
            originAirport: defaultOrigin,
            promoCode: offer.code,
            hotelName: _extractHotelName(offer),
            displayName: match.$1.name,
          );
        }
      }
    }

    // 3. Search text (Title, subtitle, code) for known destinations
    final match = _matchCityAndAirport(fullText);
    if (match != null) {
      return OfferPrefillData(
        bookingType: bookingType,
        city: match.$1,
        destinationAirport: match.$2,
        originAirport: defaultOrigin,
        promoCode: offer.code,
        hotelName: _extractHotelName(offer),
        displayName: match.$1.name,
      );
    }

    // 4. Default fallback based on offer category or Cairo as user mentioned
    // If the offer mentions Cairo (القاهرة), default to Cairo
    if (fullText.contains('cairo') || fullText.contains('قاهر')) {
      const cairoCity = TravelCity(
        code: 'CAI',
        name: 'Cairo',
        country: 'Egypt',
      );
      const cairoAirport = Airport(
        code: 'CAI',
        name: 'Cairo International Airport',
        city: 'Cairo',
      );
      return OfferPrefillData(
        bookingType: bookingType,
        city: cairoCity,
        destinationAirport: cairoAirport,
        originAirport: defaultOrigin,
        promoCode: offer.code,
        hotelName: _extractHotelName(offer),
        displayName: 'Cairo',
      );
    }

    // Fallback: Jeddah for hotels, Dubai for flights
    if (isFlight) {
      const dxbCity = TravelCity(
        code: 'DXB',
        name: 'Dubai',
        country: 'United Arab Emirates',
      );
      const dxbAirport = Airport(
        code: 'DXB',
        name: 'Dubai International Airport',
        city: 'Dubai',
      );
      return OfferPrefillData(
        bookingType: bookingType,
        city: dxbCity,
        destinationAirport: dxbAirport,
        originAirport: defaultOrigin,
        promoCode: offer.code,
        hotelName: null,
        displayName: 'Dubai',
      );
    }

    return OfferPrefillData(
      bookingType: bookingType,
      city: defaultCity,
      destinationAirport: defaultDestination,
      originAirport: defaultOrigin,
      promoCode: offer.code,
      hotelName: _extractHotelName(offer),
      displayName: defaultCity.name,
    );
  }

  static (TravelCity, Airport)? _matchCityAndAirport(String text) {
    final lower = text.toLowerCase();

    // Cairo / القاهرة
    if (lower.contains('cairo') ||
        lower.contains('قاهرة') ||
        lower.contains('قاهره') ||
        lower.contains('القاهرة') ||
        lower.contains('cai') ||
        lower.contains('100103')) {
      return (
        const TravelCity(code: 'CAI', name: 'Cairo', country: 'Egypt'),
        const Airport(
          code: 'CAI',
          name: 'Cairo International Airport',
          city: 'Cairo',
        ),
      );
    }

    // Dubai / دبي
    if (lower.contains('dubai') ||
        lower.contains('دبي') ||
        lower.contains('dxb')) {
      return (
        const TravelCity(
          code: 'DXB',
          name: 'Dubai',
          country: 'United Arab Emirates',
        ),
        const Airport(
          code: 'DXB',
          name: 'Dubai International Airport',
          city: 'Dubai',
        ),
      );
    }

    // Riyadh / الرياض
    if (lower.contains('riyadh') ||
        lower.contains('رياض') ||
        lower.contains('الرياض') ||
        lower.contains('ruh')) {
      return (
        const TravelCity(
          code: 'RUH',
          name: 'Riyadh',
          country: 'Saudi Arabia',
        ),
        const Airport(
          code: 'RUH',
          name: 'King Khalid International Airport',
          city: 'Riyadh',
        ),
      );
    }

    // Jeddah / جدة
    if (lower.contains('jeddah') ||
        lower.contains('جدة') ||
        lower.contains('جدّة') ||
        lower.contains('jed') ||
        lower.contains('113116')) {
      return (
        const TravelCity(
          code: '113116',
          name: 'Jeddah',
          country: 'Saudi Arabia',
        ),
        const Airport(
          code: 'JED',
          name: 'King Abdulaziz International Airport',
          city: 'Jeddah',
        ),
      );
    }

    // AlUla / العلا
    if (lower.contains('alula') ||
        lower.contains('al-ula') ||
        lower.contains('العلا') ||
        lower.contains('علا') ||
        lower.contains('ulh') ||
        lower.contains('113118')) {
      return (
        const TravelCity(
          code: 'ULH',
          name: 'AlUla',
          country: 'Saudi Arabia',
        ),
        const Airport(
          code: 'ULH',
          name: 'AlUla International Airport',
          city: 'AlUla',
        ),
      );
    }

    // Dammam / الدمام
    if (lower.contains('dammam') ||
        lower.contains('الدمام') ||
        lower.contains('دمام') ||
        lower.contains('dmm')) {
      return (
        const TravelCity(
          code: 'DMM',
          name: 'Dammam',
          country: 'Saudi Arabia',
        ),
        const Airport(
          code: 'DMM',
          name: 'King Fahd International Airport',
          city: 'Dammam',
        ),
      );
    }

    // Alexandria / الإسكندرية
    if (lower.contains('alexandria') ||
        lower.contains('اسكندرية') ||
        lower.contains('إسكندرية') ||
        lower.contains('الإسكندرية') ||
        lower.contains('hbe')) {
      return (
        const TravelCity(
          code: 'HBE',
          name: 'Alexandria',
          country: 'Egypt',
        ),
        const Airport(
          code: 'HBE',
          name: 'Borg El Arab Airport',
          city: 'Alexandria',
        ),
      );
    }

    // Sharm El Sheikh / شرم الشيخ
    if (lower.contains('sharm') ||
        lower.contains('شرم') ||
        lower.contains('ssh')) {
      return (
        const TravelCity(
          code: 'SSH',
          name: 'Sharm El Sheikh',
          country: 'Egypt',
        ),
        const Airport(
          code: 'SSH',
          name: 'Sharm El Sheikh Airport',
          city: 'Sharm El Sheikh',
        ),
      );
    }

    // Hurghada / الغردقة
    if (lower.contains('hurghada') ||
        lower.contains('غردقة') ||
        lower.contains('الغردقة') ||
        lower.contains('hrg')) {
      return (
        const TravelCity(
          code: 'HRG',
          name: 'Hurghada',
          country: 'Egypt',
        ),
        const Airport(
          code: 'HRG',
          name: 'Hurghada International Airport',
          city: 'Hurghada',
        ),
      );
    }

    // Istanbul / اسطنبول
    if (lower.contains('istanbul') ||
        lower.contains('اسطنبول') ||
        lower.contains('إسطنبول') ||
        lower.contains('ist')) {
      return (
        const TravelCity(
          code: 'IST',
          name: 'Istanbul',
          country: 'Turkey',
        ),
        const Airport(
          code: 'IST',
          name: 'Istanbul Airport',
          city: 'Istanbul',
        ),
      );
    }

    // London / لندن
    if (lower.contains('london') ||
        lower.contains('لندن') ||
        lower.contains('lhr') ||
        lower.contains('lon')) {
      return (
        const TravelCity(
          code: 'LON',
          name: 'London',
          country: 'United Kingdom',
        ),
        const Airport(
          code: 'LHR',
          name: 'Heathrow Airport',
          city: 'London',
        ),
      );
    }

    // Paris / باريس
    if (lower.contains('paris') ||
        lower.contains('باريس') ||
        lower.contains('cdg') ||
        lower.contains('par')) {
      return (
        const TravelCity(
          code: 'PAR',
          name: 'Paris',
          country: 'France',
        ),
        const Airport(
          code: 'CDG',
          name: 'Charles de Gaulle Airport',
          city: 'Paris',
        ),
      );
    }

    return null;
  }

  static String? _extractHotelName(TravelOffer offer) {
    final title = offer.titleKey;
    if (title.contains('فندق') || title.toLowerCase().contains('hotel')) {
      return title;
    }
    return null;
  }
}
