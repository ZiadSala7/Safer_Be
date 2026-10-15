import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/features/search/domain/entities/airport.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_offer.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_search.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_booking_details.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_offer.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_search.dart';
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

  test('HotelBookingDetails parses various backend responses accurately', () {
    final confirmedJson = {
      'success': true,
      'source': 'database',
      'booking': {
        'booking_reference': 'SAFER-1786652184-9123',
        'status': 'confirmed',
        'hotel_code': 'JP046300',
        'hotel_name': 'Allsun Hotel Pilarí Playa',
        'check_in': '2026-09-10',
        'check_out': '2026-09-12',
        'total_price': 94.3,
        'currency': 'EUR',
        'supplier': 'juniper',
        'confirmation_number': 'CONF-998811',
        'supplier_booking_id': 'SUP-554433',
        'guest_details': {
          'first_name': 'John',
          'last_name': 'Doe',
          'email': 'john@example.com',
          'phone': '+966500000000',
        },
      },
    };

    final details = HotelBookingDetails.fromJson(confirmedJson);
    expect(details.bookingReference, 'SAFER-1786652184-9123');
    expect(details.hotelName, 'Allsun Hotel Pilarí Playa');
    expect(details.isConfirmed, isTrue);
    expect(details.isPending, isFalse);
    expect(details.confirmationNumber, 'CONF-998811');
    expect(details.leadGuestName, 'John Doe');
    expect(details.totalPrice, 94.3);
    expect(details.currency, 'EUR');
    expect(details.supplier, 'juniper');

    final pendingJson = {
      'success': true,
      'booking': {
        'reference': 'SAFER-1786652184-9123',
        'status': 'pending',
        'payment_status': 'Pending',
      },
    };
    final pendingDetails = HotelBookingDetails.fromJson(pendingJson);
    expect(pendingDetails.bookingReference, 'SAFER-1786652184-9123');
    expect(pendingDetails.isPending, isTrue);
    expect(pendingDetails.isConfirmed, isFalse);

    final failedJson = {
      'success': true,
      'booking': {
        'reference': 'SAFER-1786652184-9123',
        'status': 'paid_but_booking_failed',
      },
    };
    final failedDetails = HotelBookingDetails.fromJson(failedJson);
    expect(failedDetails.isFailed, isTrue);
  });

  test('HotelPaymentCallbackResult parses callback response correctly', () {
    final successCallback = {
      'success': true,
      'booking_reference': 'SAFER-1786652184-9123',
      'paymentId': '123456789',
      'payment_status': 'Paid',
      'status': 'confirmed',
      'message': 'Payment completed and booking confirmed.',
    };

    final result = HotelPaymentCallbackResult.fromJson(successCallback);
    expect(result.success, isTrue);
    expect(result.bookingReference, 'SAFER-1786652184-9123');
    expect(result.paymentId, '123456789');
    expect(result.isPaid, isTrue);
    expect(result.isConfirmed, isTrue);

    final failedCallback = {
      'success': false,
      'paymentId': '123456789',
      'payment_status': 'Failed',
      'message': 'Payment failed.',
    };

    final failedResult = HotelPaymentCallbackResult.fromJson(failedCallback);
    expect(failedResult.isFailed, isTrue);
    expect(failedResult.isPaid, isFalse);
  });

  test('HotelSearchRoom handles default and multi-guest configurations', () {
    const defaultRoom = HotelSearchRoom();
    expect(defaultRoom.adults, 2);
    expect(defaultRoom.children, 0);
    expect(defaultRoom.childAges, isEmpty);
    expect(defaultRoom.totalGuests, 2);

    final customRoom = defaultRoom.copyWith(
      adults: 3,
      children: 2,
      childAges: [4, 7],
    );
    expect(customRoom.adults, 3);
    expect(customRoom.children, 2);
    expect(customRoom.childAges, [4, 7]);
    expect(customRoom.totalGuests, 5);

    final json = customRoom.toJson();
    expect(json['adults'], 3);
    expect(json['children'], 2);
    expect(json['child_ages'], [4, 7]);

    final parsed = HotelSearchRoom.fromJson(json);
    expect(parsed, equals(customRoom));
  });

  test('HotelSearch computes totals and serializes roomList with website parity', () {
    final search = HotelSearch(
      cityCode: '113116',
      checkIn: DateTime(2026, 11, 1),
      checkOut: DateTime(2026, 11, 4),
      roomList: const [
        HotelSearchRoom(adults: 2, children: 1, childAges: [6]),
        HotelSearchRoom(adults: 1, children: 2, childAges: [3, 9]),
      ],
      currency: 'SAR',
    );

    expect(search.effectiveRooms, 2);
    expect(search.effectiveAdults, 3);
    expect(search.effectiveChildren, 3);
    expect(search.effectiveChildAges, [6, 3, 9]);
    expect(search.totalGuests, 6);

    final json = search.toJson();
    expect(json['city_code'], '113116');
    expect(json['rooms'], 2);
    expect(json['adults'], 3);
    expect(json['children'], 3);
    expect(json['child_ages'], [6, 3, 9]);
    expect(json['room_guests'], isA<List>());
    expect((json['room_guests'] as List).length, 2);
  });
}
