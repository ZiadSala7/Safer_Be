import '../entities/trip.dart';

abstract interface class TripsRepository {
  Future<List<Trip>> get upcoming;
  Future<List<Trip>> get past;
  Future<void> saveTrip(Trip trip);
}
