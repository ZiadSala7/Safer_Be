import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../search/domain/entities/hotel_booking_details.dart';
import '../../domain/entities/flight_booking_details.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';

class LocalTripsRepository implements TripsRepository {
  static const _key = 'safer_be_trips';

  @override
  Future<List<Trip>> get upcoming async {
    final trips = await _loadAll();
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
    final trips = await _loadAll();
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
    final trips = await _loadAll();
    final existingIndex = trips.indexWhere(
      (t) => t.reference.isNotEmpty && t.reference == trip.reference,
    );
    if (existingIndex >= 0) {
      trips[existingIndex] = trip;
    } else {
      trips.add(trip);
    }
    await _saveAll(trips);
  }

  @override
  Future<void> removeTrip(String reference) async {
    final trips = await _loadAll();
    trips.removeWhere((t) => t.reference == reference);
    await _saveAll(trips);
  }

  @override
  Future<FlightBookingDetails> getFlightBookingDetails(
    String reference, {
    String? guestEmail,
    String? guestLastName,
  }) async {
    final trips = await _loadAll();
    final match = trips.firstWhere(
      (t) => t.reference == reference,
      orElse: () => Trip(route: 'Flight', date: '', provider: '', reference: reference),
    );
    return FlightBookingDetails(
      bookingReference: match.reference,
      pnr: match.pnr,
      status: match.status,
      totalPrice: match.price,
      currency: match.currency,
    );
  }

  @override
  Future<HotelBookingDetails> getHotelBookingDetails(
    String reference, {
    String? guestEmail,
    String? guestLastName,
  }) async {
    final trips = await _loadAll();
    final match = trips.firstWhere(
      (t) => t.reference == reference,
      orElse: () => Trip(route: 'Hotel', date: '', provider: '', reference: reference, type: 'hotel'),
    );
    return HotelBookingDetails(
      bookingReference: match.reference,
      status: match.status,
      hotelName: match.route,
      totalPrice: match.price,
      currency: match.currency,
    );
  }

  @override
  Future<void> releaseFlightBooking(String reference) async {
    final trips = await _loadAll();
    final idx = trips.indexWhere((t) => t.reference == reference);
    if (idx >= 0) {
      final t = trips[idx];
      trips[idx] = Trip(
        route: t.route,
        date: t.date,
        provider: t.provider,
        reference: t.reference,
        type: t.type,
        status: 'released',
        pnr: t.pnr,
        price: t.price,
        currency: t.currency,
      );
      await _saveAll(trips);
    }
  }

  @override
  Future<Map<String, dynamic>> requestFlightRefund(
    String reference, {
    num? amount,
    String? reason,
  }) async {
    return {'status': 'refund_requested', 'booking_reference': reference};
  }

  @override
  Future<Uint8List> downloadFlightInvoice(String reference) async {
    return Uint8List(0);
  }

  @override
  Future<Uint8List> downloadFlightTicket(String reference) async {
    return Uint8List(0);
  }

  @override
  Future<void> cancelHotelBooking(String reference, {String? reason}) async {
    final trips = await _loadAll();
    final idx = trips.indexWhere((t) => t.reference == reference);
    if (idx >= 0) {
      final t = trips[idx];
      trips[idx] = Trip(
        route: t.route,
        date: t.date,
        provider: t.provider,
        reference: t.reference,
        type: t.type,
        status: 'cancelled',
        pnr: t.pnr,
        price: t.price,
        currency: t.currency,
      );
      await _saveAll(trips);
    }
  }

  @override
  Future<List<Trip>> getCustomerBookings(String customerId, {String? adminToken}) async {
    return _loadAll();
  }

  Future<List<Trip>> _loadAll() async {
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

  Future<void> _saveAll(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(trips.map((t) => t.toJson()).toList()),
    );
  }
}
