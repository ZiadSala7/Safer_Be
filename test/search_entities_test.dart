import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/features/search/domain/entities/airport.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_offer.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_search.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_offer.dart';
import 'package:safer_be_project/features/search/domain/entities/travel_city.dart';

void main() {
  test('flight request matches the Postman contract', () {
    final json = FlightSearch(
      origin: 'CAI',
      destination: 'DXB',
      departure: DateTime(2026, 7, 15),
    ).toJson();

    expect(json['JourneyType'], 1);
    expect(json['Origin'], 'CAI');
    expect(json['DepartureDate'], '2026-07-15');
    expect(json['AdultCount'], 1);
  });

  test('API entities tolerate snake and camel case responses', () {
    final airport = Airport.fromJson({
      'iata_code': 'CAI',
      'airport_name': 'Cairo International',
      'city_name': 'Cairo',
    });
    final flight = FlightOffer.fromJson({
      'result_index': 'result_0',
      'airline_name': 'EgyptAir',
      'total_price': 350.5,
      'currency': 'USD',
      'segments': [
        {
          'origin': {'code': 'CAI'},
          'destination': {'code': 'DXB'},
        },
      ],
    });
    final hotel = HotelOffer.fromJson({
      'hotel_code': 'HTL1',
      'hotel_name': 'Safer Stay',
      'min_price': 420,
      'currency': 'SAR',
      'star_rating': 5,
    });

    expect(airport.code, 'CAI');
    expect(flight.route, contains('DXB'));
    expect(hotel.name, 'Safer Stay');
  });

  test('entities parse the verified production response shapes', () {
    final flight = FlightOffer.fromJson({
      'id': 'offer-1',
      'legs': [
        {
          'origin_code': 'CAI',
          'destination_code': 'AUH',
          'departure_time': '2026-07-15T02:25:00',
          'arrival_time': '2026-07-15T06:55:00',
          'duration_minutes': 210,
          'airline_name': 'Etihad Airways',
          'cabin_class': 'Business',
        },
        {
          'origin_code': 'AUH',
          'destination_code': 'XNB',
          'departure_time': '2026-07-15T08:25:00',
          'arrival_time': '2026-07-15T10:25:00',
          'duration_minutes': 120,
        },
      ],
      'price': {'total': 249.2, 'currency': 'USD'},
      'baggage': {'description': 'Checked: 0 KG | Cabin: 7 KG'},
      'refundable': false,
      'best_deal_labels': ['Cheapest'],
    });
    final hotel = HotelOffer.fromJson({
      'hotel_code': '1208652',
      'hotel_name': "Traveler's House",
      'min_price': 23.25,
      'currency': 'USD',
      'images': [
        {'url': 'https://example.com/hotel.jpg'},
      ],
    });
    final city = TravelCity.fromJson({
      'code': '113116',
      'name': 'Cairo',
      'countryName': 'Egypt',
    });

    expect(flight.route, 'CAI → XNB');
    expect(flight.airline, 'Etihad Airways');
    expect(flight.price, 249.2);
    expect(flight.durationMinutes, 330);
    expect(flight.stops, 1);
    expect(flight.labels, ['Cheapest']);
    expect(hotel.imageUrl, 'https://example.com/hotel.jpg');
    expect(city.country, 'Egypt');
  });

  test('round trip request includes passengers, return date, and cabin', () {
    final json = FlightSearch(
      origin: 'CAI',
      destination: 'DXB',
      departure: DateTime(2026, 7, 15),
      returnDate: DateTime(2026, 7, 25),
      adults: 2,
      children: 1,
      infants: 1,
      cabinClass: 2,
    ).toJson();

    expect(json['JourneyType'], 2);
    expect(json['ReturnDate'], '2026-07-25');
    expect(json['AdultCount'], 2);
    expect(json['ChildCount'], 1);
    expect(json['InfantCount'], 1);
    expect(json['FlightCabinClass'], 2);
  });
}
