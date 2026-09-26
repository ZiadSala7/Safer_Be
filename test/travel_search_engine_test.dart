import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_offer.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_offer.dart';
import 'package:safer_be_project/features/search/domain/utils/travel_search_engine.dart';
import 'package:safer_be_project/features/search/presentation/widgets/flight_filter_sheet.dart';
import 'package:safer_be_project/features/search/presentation/widgets/hotel_filter_sheet.dart';

void main() {
  group('TravelSearchEngine Flights Tests', () {
    final flightSaudiaDirect = FlightOffer(
      id: '1',
      airline: 'Saudia',
      airlineCode: 'SV',
      route: 'CAI → JED',
      time: '08:00 AM',
      price: 450,
      currency: 'SAR',
      departureTime: DateTime(2026, 9, 24, 8, 0),
      arrivalTime: DateTime(2026, 9, 24, 10, 15),
      durationMinutes: 135,
      stops: 0,
      cabinClass: 'Economy',
      baggage: '1 piece 23kg',
      refundable: true,
      labels: ['Direct'],
    );

    final flightFlynasTransit = FlightOffer(
      id: '2',
      airline: 'flynas',
      airlineCode: 'XY',
      route: 'CAI → JED',
      time: '08:00 PM',
      price: 320,
      currency: 'SAR',
      departureTime: DateTime(2026, 9, 24, 20, 0),
      arrivalTime: DateTime(2026, 9, 25, 2, 0),
      durationMinutes: 360,
      stops: 1,
      cabinClass: 'Economy',
      baggage: '0kg checked baggage',
      refundable: false,
      labels: [],
    );

    final flightEgyptAirDirect = FlightOffer(
      id: '3',
      airline: 'EgyptAir',
      airlineCode: 'MS',
      route: 'CAI → JED',
      time: '02:00 PM',
      price: 600,
      currency: 'SAR',
      departureTime: DateTime(2026, 9, 24, 14, 0),
      arrivalTime: DateTime(2026, 9, 24, 16, 20),
      durationMinutes: 140,
      stops: 0,
      cabinClass: 'Economy',
      baggage: '2 pieces 23kg checked',
      refundable: true,
      labels: ['Best'],
    );

    final allFlights = [flightSaudiaDirect, flightFlynasTransit, flightEgyptAirDirect];

    test('Filters by Arabic airline alias (طيران ناس)', () {
      final res = TravelSearchEngine.filterFlights(
        offers: allFlights,
        filters: FlightFilterState(),
        query: 'طيران ناس',
      );
      expect(res.length, 1);
      expect(res.first.airlineCode, 'XY');
    });

    test('Filters by direct flights in Arabic (رحلات مباشرة)', () {
      final res = TravelSearchEngine.filterFlights(
        offers: allFlights,
        filters: FlightFilterState(),
        query: 'رحلات مباشرة',
      );
      expect(res.length, 2);
      expect(res.every((f) => f.stops == 0), isTrue);
    });

    test('Filters by checked baggage in Arabic (شامل الأمتعة)', () {
      final res = TravelSearchEngine.filterFlights(
        offers: allFlights,
        filters: FlightFilterState(),
        query: 'شامل الأمتعة',
      );
      expect(res.length, 2);
      expect(res.every((f) => f.hasCheckedBaggage), isTrue);
    });

    test('Filters by morning flights in Arabic (رحلات صباحية)', () {
      final res = TravelSearchEngine.filterFlights(
        offers: allFlights,
        filters: FlightFilterState(),
        query: 'رحلات صباحية',
      );
      expect(res.length, 1);
      expect(res.first.airline, 'Saudia');
    });

    test('Filters by max price (أقل من 500)', () {
      final res = TravelSearchEngine.filterFlights(
        offers: allFlights,
        filters: FlightFilterState(),
        query: 'أقل من 500',
      );
      expect(res.length, 2);
      expect(res.every((f) => f.price <= 500), isTrue);
    });

    test('Combined AI query (أرخص الرحلات المباشرة مع السعودية)', () {
      final res = TravelSearchEngine.filterFlights(
        offers: allFlights,
        filters: FlightFilterState(),
        query: 'أرخص الرحلات المباشرة مع الخطوط السعودية',
      );
      expect(res.length, 1);
      expect(res.first.airline, 'Saudia');
      expect(res.first.stops, 0);
    });
  });

  group('TravelSearchEngine Hotels Tests', () {
    final hotelHilton5Star = HotelOffer(
      code: 'H1',
      name: 'Hilton Riyadh Hotel & Residences',
      supplier: 'Juniper',
      location: 'Al Olaya, Riyadh',
      price: 850,
      currency: 'SAR',
      rating: 5,
      imageUrl: '',
      description: 'Luxury 5-star hotel with outdoor swimming pool, spa and breakfast.',
      amenities: ['swimming pool', 'free wifi', 'breakfast', 'spa', 'free cancellation'],
    );

    final hotelIbis3Star = HotelOffer(
      code: 'H2',
      name: 'Ibis Riyadh Olaya Street',
      supplier: 'TBO',
      location: 'Olaya Street, Riyadh',
      price: 280,
      currency: 'SAR',
      rating: 3,
      imageUrl: '',
      description: 'Budget friendly stay in central Riyadh.',
      amenities: ['free wifi', 'air conditioning'],
    );

    final hotelMarriott4Star = HotelOffer(
      code: 'H3',
      name: 'Courtyard by Marriott Riyadh Diplomatic Quarter',
      supplier: 'Juniper',
      location: 'Diplomatic Quarter, Riyadh',
      price: 520,
      currency: 'SAR',
      rating: 4,
      imageUrl: '',
      description: 'Modern 4-star hotel with fitness center and restaurant.',
      amenities: ['gym', 'fitness', 'breakfast buffet', 'free wifi'],
    );

    final allHotels = [hotelHilton5Star, hotelIbis3Star, hotelMarriott4Star];

    test('Filters by 5 stars query in Arabic (فنادق 5 نجوم)', () {
      final res = TravelSearchEngine.filterHotels(
        offers: allHotels,
        filters: HotelFilterState(),
        query: 'فنادق 5 نجوم',
      );
      expect(res.length, 1);
      expect(res.first.rating, 5);
      expect(res.first.name, contains('Hilton'));
    });

    test('Filters by pool in Arabic (مسبح)', () {
      final res = TravelSearchEngine.filterHotels(
        offers: allHotels,
        filters: HotelFilterState(),
        query: 'مسبح',
      );
      expect(res.length, 1);
      expect(res.first.name, contains('Hilton'));
    });

    test('Filters by hotel name (هيلتون / Hilton)', () {
      final res = TravelSearchEngine.filterHotels(
        offers: allHotels,
        filters: HotelFilterState(),
        query: 'Hilton',
      );
      expect(res.length, 1);
      expect(res.first.code, 'H1');
    });

    test('Filters by price (أقل من 300)', () {
      final res = TravelSearchEngine.filterHotels(
        offers: allHotels,
        filters: HotelFilterState(),
        query: 'أقل من 300',
      );
      expect(res.length, 1);
      expect(res.first.code, 'H2');
    });

    test('Sorts by cheapest (أرخص الفنادق)', () {
      final res = TravelSearchEngine.filterHotels(
        offers: allHotels,
        filters: HotelFilterState(),
        query: 'أرخص الفنادق',
      );
      expect(res.first.price, 280);
      expect(res.last.price, 850);
    });
  });
}
