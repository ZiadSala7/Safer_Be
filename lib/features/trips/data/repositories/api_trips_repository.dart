import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_read.dart';
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
    trips.add(trip);
    await _saveAllLocal(trips);
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
        final booking = data is Map ? (data['booking'] ?? data) : null;
        if (booking is Map) {
          final liveStatus = readText(booking, ['status'], trip.status);
          updated.add(Trip(
            route: trip.route,
            date: trip.date,
            provider: trip.provider,
            reference: trip.reference,
            type: trip.type,
            status: liveStatus,
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
