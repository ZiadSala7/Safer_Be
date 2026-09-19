import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_read.dart';
import '../../../search/domain/entities/hotel_booking_details.dart';
import '../../domain/entities/flight_booking_details.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';

class ApiTripsRepository implements TripsRepository {
  ApiTripsRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  static const _key = 'safer_be_trips';

  @override
  Future<List<Trip>> get upcoming async {
    final trips = await _loadAndRefreshAll();
    final now = DateTime.now();
    return trips
        .where((t) {
          final date = DateTime.tryParse(t.date);
          return date != null && date.isAfter(now);
        })
        .toList()
      ..sort(
        (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)),
      );
  }

  @override
  Future<List<Trip>> get past async {
    final trips = await _loadAndRefreshAll();
    final now = DateTime.now();
    return trips
        .where((t) {
          final date = DateTime.tryParse(t.date);
          return date == null || date.isBefore(now);
        })
        .toList()
      ..sort(
        (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
      );
  }

  @override
  Future<void> saveTrip(Trip trip) async {
    final trips = await _loadAllLocal();
    final existingIndex = trips.indexWhere(
      (t) => t.reference.isNotEmpty && t.reference == trip.reference,
    );
    if (existingIndex >= 0) {
      trips[existingIndex] = trip;
    } else {
      trips.add(trip);
    }
    await _saveAllLocal(trips);
  }

  @override
  Future<void> removeTrip(String reference) async {
    final trips = await _loadAllLocal();
    trips.removeWhere((t) => t.reference == reference);
    await _saveAllLocal(trips);
  }

  /// Flight Booking Details (Owner or Guest Challenge)
  /// - Owner: GET /api/v1/flights/booking/{reference} (Bearer token)
  /// - Guest: GET /api/v1/flights/booking/{reference}?email={email}&last_name={last_name} (Public)
  @override
  Future<FlightBookingDetails> getFlightBookingDetails(
    String reference, {
    String? guestEmail,
    String? guestLastName,
  }) async {
    final query = <String, String>{};
    final isGuest = guestEmail != null &&
        guestEmail.trim().isNotEmpty &&
        guestLastName != null &&
        guestLastName.trim().isNotEmpty;

    if (isGuest) {
      query['email'] = guestEmail.trim();
      query['last_name'] = guestLastName.trim();
    }

    final json = await _client.get(
      '/flights/booking/$reference',
      query: query.isEmpty ? null : query,
      authenticated: !isGuest,
    );
    final details = FlightBookingDetails.fromJson(json);

    // Sync live status with local storage
    if (reference.isNotEmpty) {
      final origin = details.origin.isNotEmpty ? details.origin : '';
      final destination = details.destination.isNotEmpty ? details.destination : '';
      final route = (origin.isNotEmpty && destination.isNotEmpty)
          ? '$origin → $destination'
          : (details.airline.isNotEmpty ? details.airline : 'Flight Booking');

      await saveTrip(
        Trip(
          route: route,
          date: details.departureTime.split('T').first,
          provider: details.airline.isNotEmpty ? details.airline : 'Flight',
          reference: details.bookingReference.isNotEmpty ? details.bookingReference : reference,
          type: 'flight',
          status: details.status,
          pnr: details.pnr,
          price: details.totalPrice,
          currency: details.currency,
        ),
      );
    }

    return details;
  }

  /// Hotel Booking Details (Owner or Guest Challenge)
  /// - Owner: GET /api/v1/hotels/booking/{reference} (Bearer token)
  /// - Guest: GET /api/v1/hotels/booking/{reference}?email={email}&last_name={last_name} (Public)
  @override
  Future<HotelBookingDetails> getHotelBookingDetails(
    String reference, {
    String? guestEmail,
    String? guestLastName,
  }) async {
    final query = <String, String>{};
    final isGuest = guestEmail != null &&
        guestEmail.trim().isNotEmpty &&
        guestLastName != null &&
        guestLastName.trim().isNotEmpty;

    if (isGuest) {
      query['email'] = guestEmail.trim();
      query['last_name'] = guestLastName.trim();
    }

    final json = await _client.get(
      '/hotels/booking/$reference',
      query: query.isEmpty ? null : query,
      authenticated: !isGuest,
    );
    final details = HotelBookingDetails.fromJson(json);

    // Sync live status with local storage
    if (reference.isNotEmpty) {
      await saveTrip(
        Trip(
          route: details.hotelName.isNotEmpty ? details.hotelName : 'Hotel Stay',
          date: details.checkIn.isNotEmpty ? details.checkIn : '',
          provider: details.supplier.isNotEmpty ? details.supplier.toUpperCase() : 'HOTEL',
          reference: details.bookingReference.isNotEmpty ? details.bookingReference : reference,
          type: 'hotel',
          status: details.status,
          price: details.totalPrice,
          currency: details.currency,
        ),
      );
    }

    return details;
  }

  /// Release Flight PNR (Owner)
  /// POST /api/v1/flights/booking/{reference}/release
  @override
  Future<void> releaseFlightBooking(String reference) async {
    await _client.post('/flights/booking/$reference/release');
    // Update cached status
    await _updateTripStatus(reference, 'released');
  }

  /// Request Flight Refund (Owner)
  /// POST /api/v1/flights/booking/{reference}/refund
  /// Body: {"amount": 490, "reason": "Customer request"}
  @override
  Future<Map<String, dynamic>> requestFlightRefund(
    String reference, {
    num? amount,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      if (amount != null && amount > 0) 'amount': amount,
      'reason': reason != null && reason.trim().isNotEmpty
          ? reason.trim()
          : 'Customer request',
    };
    final json = await _client.post('/flights/booking/$reference/refund', body: body);
    await _updateTripStatus(reference, 'refunded');
    final data = apiData(json);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Download Flight Invoice PDF (Owner)
  /// GET /api/v1/flights/booking/{reference}/invoice
  @override
  Future<Uint8List> downloadFlightInvoice(String reference) async {
    return _client.getBytes('/flights/booking/$reference/invoice');
  }

  /// Download Flight Ticket PDF (Owner)
  /// GET /api/v1/flights/booking/{reference}/ticket
  @override
  Future<Uint8List> downloadFlightTicket(String reference) async {
    return _client.getBytes('/flights/booking/$reference/ticket');
  }

  /// Request Hotel Cancellation (Owner)
  /// POST /api/v1/hotels/booking/{reference}/cancel
  /// Body: {"reason": "Customer cancellation"}
  @override
  Future<void> cancelHotelBooking(String reference, {String? reason}) async {
    final body = <String, dynamic>{
      'reason': reason != null && reason.trim().isNotEmpty
          ? reason.trim()
          : 'Customer cancellation',
    };
    await _client.post('/hotels/booking/$reference/cancel', body: body);
    await _updateTripStatus(reference, 'cancelled');
  }

  /// Admin operation: Get Customer Bookings
  /// GET /api/v1/admin/customers/{customer_id}/bookings
  @override
  Future<List<Trip>> getCustomerBookings(String customerId, {String? adminToken}) async {
    final json = await _client.get(
      '/admin/customers/$customerId/bookings',
      customToken: adminToken,
    );
    final data = apiData(json);
    final rawList = data is List
        ? data
        : (data is Map && data['bookings'] is List
            ? data['bookings'] as List
            : (json is Map && json['data'] is List ? json['data'] as List : []));

    return rawList.whereType<Map>().map((m) {
      final map = Map<String, dynamic>.from(m);
      final ref = readText(map, ['booking_reference', 'reference', 'pnr']);
      final type = readText(map, ['type', 'booking_type', 'product_type'], 'flight').toLowerCase();
      final route = readText(
        map,
        ['route', 'hotel_name', 'name', 'destination', 'flight_route'],
        type == 'hotel' ? 'Hotel Booking' : 'Flight Booking',
      );
      final date = readText(map, ['date', 'departure_date', 'check_in', 'created_at']);
      final provider = readText(map, ['provider', 'airline', 'supplier'], 'Safer Be');
      final status = readText(map, ['status', 'booking_status'], 'confirmed');
      final price = readNumber(map, ['total_price', 'total', 'amount', 'price']);
      final currency = readText(map, ['currency'], 'SAR');
      final pnr = readText(map, ['pnr', 'pnr_code']);

      return Trip(
        route: route,
        date: date,
        provider: provider,
        reference: ref,
        type: type,
        status: status,
        pnr: pnr,
        price: price,
        currency: currency,
      );
    }).toList();
  }

  Future<void> _updateTripStatus(String reference, String newStatus) async {
    final trips = await _loadAllLocal();
    final idx = trips.indexWhere((t) => t.reference == reference);
    if (idx >= 0) {
      final t = trips[idx];
      trips[idx] = Trip(
        route: t.route,
        date: t.date,
        provider: t.provider,
        reference: t.reference,
        type: t.type,
        status: newStatus,
        pnr: t.pnr,
        price: t.price,
        currency: t.currency,
      );
      await _saveAllLocal(trips);
    }
  }

  Future<List<Trip>> _loadAndRefreshAll() async {
    final trips = await _loadAllLocal();
    final updated = <Trip>[];

    for (final trip in trips) {
      if (trip.reference.isEmpty) {
        updated.add(trip);
        continue;
      }
      try {
        final path = trip.type == 'hotel'
            ? '/hotels/booking/${trip.reference}'
            : '/flights/booking/${trip.reference}';
        final response = await _client.get(path);
        final data = apiData(response);
        final booking = data is Map ? (data['booking'] ?? data['data'] ?? data) : null;
        if (booking is Map) {
          final liveStatus = readText(booking, ['status'], trip.status);
          final price = readNumber(booking, ['total_price', 'price', 'amount'], trip.price);
          final currency = readText(booking, ['currency'], trip.currency);
          final pnr = readText(booking, ['pnr'], trip.pnr);
          updated.add(Trip(
            route: trip.route,
            date: trip.date,
            provider: trip.provider,
            reference: trip.reference,
            type: trip.type,
            status: liveStatus,
            pnr: pnr,
            price: price,
            currency: currency,
          ));
          continue;
        }
      } catch (_) {
        // Fallback to cached local trip if offline or error
      }
      updated.add(trip);
    }
    return updated;
  }

  Future<List<Trip>> _loadAllLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((m) => Trip.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAllLocal(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(trips.map((t) => t.toJson()).toList()),
    );
  }
}
