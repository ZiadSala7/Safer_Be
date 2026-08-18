import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
    trips.add(trip);
    await _saveAll(trips);
  }

  Future<List<Trip>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((m) => Trip.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
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
