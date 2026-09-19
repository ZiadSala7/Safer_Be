import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safer_be_project/core/network/api_client.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_booking_details.dart';
import 'package:safer_be_project/features/trips/data/repositories/api_trips_repository.dart';
import 'package:safer_be_project/features/trips/domain/entities/flight_booking_details.dart';
import 'package:safer_be_project/features/trips/domain/entities/trip.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('Traveling Safer My Bookings - Models & Entities', () {
    test('FlightBookingDetails correctly parses owner response and evaluates permissions', () {
      final json = {
        'success': true,
        'booking': {
          'booking_reference': 'BKG-2026-08-15-SV-001',
          'pnr': 'ABC123',
          'status': 'ticketed',
          'total_price': 490,
          'currency': 'SAR',
          'ticket_number': '065-1234567890',
          'flight_details': {
            'airline': 'Saudia',
            'airline_code': 'SV',
            'flight_number': 'SV 123',
            'origin': 'RUH',
            'destination': 'JED',
            'departure_time': '2026-09-10T08:00:00Z',
            'arrival_time': '2026-09-10T09:40:00Z',
            'duration': '1h 40m',
            'cabin_class': 'Economy',
          },
          'passengers': [
            {
              'first_name': 'John',
              'last_name': 'Smith',
              'type': 'Adult',
              'ticket_number': '065-1234567890',
            }
          ]
        }
      };

      final details = FlightBookingDetails.fromJson(json);

      expect(details.bookingReference, 'BKG-2026-08-15-SV-001');
      expect(details.pnr, 'ABC123');
      expect(details.isTicketed, isTrue);
      expect(details.canDownloadTicket, isTrue);
      expect(details.canDownloadInvoice, isTrue);
      expect(details.canRefund, isTrue);
      expect(details.canRelease, isFalse); // ticketed cannot be released
      expect(details.passengers.length, 1);
      expect(details.passengers.first.name, 'John Smith');
      expect(details.airline, 'Saudia');
    });

    test('FlightBookingDetails evaluates pending hold eligible for release', () {
      final json = {
        'success': true,
        'booking': {
          'booking_reference': 'FLT-PENDING-001',
          'pnr': 'XYZ789',
          'status': 'pending',
          'total_price': 300,
          'currency': 'SAR',
        }
      };

      final details = FlightBookingDetails.fromJson(json);

      expect(details.isPending, isTrue);
      expect(details.isTicketed, isFalse);
      expect(details.canRelease, isTrue);
      expect(details.canRefund, isFalse);
      expect(details.canDownloadTicket, isFalse);
    });

    test('HotelBookingDetails evaluates cancellation eligibility', () {
      final confirmedHotel = HotelBookingDetails.fromJson({
        'booking': {
          'booking_reference': 'HTL-CONF-001',
          'status': 'confirmed',
          'hotel_name': 'Riyadh Palace',
          'check_in': '2026-10-01',
          'check_out': '2026-10-05',
          'total_price': 1200,
          'currency': 'SAR',
        }
      });

      expect(confirmedHotel.isConfirmed, isTrue);
      expect(confirmedHotel.canCancel, isTrue);

      final cancelledHotel = HotelBookingDetails.fromJson({
        'booking': {
          'booking_reference': 'HTL-CANC-001',
          'status': 'cancelled',
        }
      });

      expect(cancelledHotel.isCancelled, isTrue);
      expect(cancelledHotel.canCancel, isFalse);
    });

    test('Trip entity serializes and deserializes with optional fields', () {
      final trip = Trip(
        route: 'RUH → JED',
        date: '2026-10-01',
        provider: 'Saudia',
        reference: 'BKG-001',
        type: 'flight',
        status: 'confirmed',
        pnr: 'PNR123',
        price: 490,
        currency: 'SAR',
      );

      final map = trip.toJson();
      final restored = Trip.fromJson(map);

      expect(restored.route, 'RUH → JED');
      expect(restored.pnr, 'PNR123');
      expect(restored.price, 490);
      expect(restored.currency, 'SAR');
    });
  });

  group('Traveling Safer My Bookings - API Repository Contracts', () {
    test('Flight booking details (owner) calls secured GET', () async {
      String? requestedPath;

      final mockClient = MockClient((request) async {
        requestedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'booking': {
              'booking_reference': 'FLT-OWNER-01',
              'status': 'confirmed',
              'pnr': 'ABCDEF',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiTripsRepository(client: apiClient);

      final details = await repo.getFlightBookingDetails('FLT-OWNER-01');

      expect(requestedPath, '/api/v1/flights/booking/FLT-OWNER-01');
      expect(details.bookingReference, 'FLT-OWNER-01');
      expect(details.pnr, 'ABCDEF');
    });

    test('Flight booking details (guest challenge) calls public endpoint with query params', () async {
      String? requestedUrl;

      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          jsonEncode({
            'success': true,
            'booking': {
              'booking_reference': 'FLT-GUEST-01',
              'status': 'confirmed',
              'pnr': 'GUEST1',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiTripsRepository(client: apiClient);

      final details = await repo.getFlightBookingDetails(
        'FLT-GUEST-01',
        guestEmail: 'traveler@example.com',
        guestLastName: 'Smith',
      );

      expect(requestedUrl, contains('/api/v1/flights/booking/FLT-GUEST-01'));
      expect(requestedUrl, contains('email=traveler%40example.com'));
      expect(requestedUrl, contains('last_name=Smith'));
      expect(details.bookingReference, 'FLT-GUEST-01');
    });

    test('Release Flight PNR calls POST /flights/booking/{ref}/release', () async {
      String? requestedPath;
      String? requestedMethod;

      final mockClient = MockClient((request) async {
        requestedPath = request.url.path;
        requestedMethod = request.method;
        return http.Response(jsonEncode({'success': true, 'message': 'Released'}), 200);
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiTripsRepository(client: apiClient);

      await repo.releaseFlightBooking('FLT-RELEASE-01');

      expect(requestedMethod, 'POST');
      expect(requestedPath, '/api/v1/flights/booking/FLT-RELEASE-01/release');
    });

    test('Request Flight Refund calls POST /flights/booking/{ref}/refund with body', () async {
      String? requestedPath;
      Map? requestBody;

      final mockClient = MockClient((request) async {
        requestedPath = request.url.path;
        requestBody = jsonDecode(request.body) as Map;
        return http.Response(
          jsonEncode({'success': true, 'data': {'status': 'refund_requested'}}),
          200,
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiTripsRepository(client: apiClient);

      final res = await repo.requestFlightRefund(
        'FLT-REFUND-01',
        amount: 490,
        reason: 'Customer request',
      );

      expect(requestedPath, '/api/v1/flights/booking/FLT-REFUND-01/refund');
      expect(requestBody?['amount'], 490);
      expect(requestBody?['reason'], 'Customer request');
      expect(res['status'], 'refund_requested');
    });

    test('Hotel booking cancellation calls POST /hotels/booking/{ref}/cancel with body', () async {
      String? requestedPath;
      Map? requestBody;

      final mockClient = MockClient((request) async {
        requestedPath = request.url.path;
        requestBody = jsonDecode(request.body) as Map;
        return http.Response(jsonEncode({'success': true}), 200);
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiTripsRepository(client: apiClient);

      await repo.cancelHotelBooking(
        'HTL-CANCEL-01',
        reason: 'Customer cancellation',
      );

      expect(requestedPath, '/api/v1/hotels/booking/HTL-CANCEL-01/cancel');
      expect(requestBody?['reason'], 'Customer cancellation');
    });

    test('Admin operation: Get customer bookings calls /admin/customers/{id}/bookings', () async {
      String? requestedPath;

      final mockClient = MockClient((request) async {
        requestedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'booking_reference': 'BKG-ADMIN-1',
                'type': 'flight',
                'route': 'RUH → DXB',
                'status': 'confirmed',
                'total_price': 550,
              },
              {
                'booking_reference': 'BKG-ADMIN-2',
                'type': 'hotel',
                'hotel_name': 'Four Seasons',
                'status': 'confirmed',
                'total_price': 1500,
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiTripsRepository(client: apiClient);

      final list = await repo.getCustomerBookings('42');

      expect(requestedPath, '/api/v1/admin/customers/42/bookings');
      expect(list.length, 2);
      expect(list[0].reference, 'BKG-ADMIN-1');
      expect(list[0].type, 'flight');
      expect(list[1].reference, 'BKG-ADMIN-2');
      expect(list[1].type, 'hotel');
    });
  });
}
