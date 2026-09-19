import 'dart:typed_data';

import '../../../search/domain/entities/hotel_booking_details.dart';
import '../entities/flight_booking_details.dart';
import '../entities/trip.dart';

abstract interface class TripsRepository {
  Future<List<Trip>> get upcoming;
  Future<List<Trip>> get past;
  Future<void> saveTrip(Trip trip);
  Future<void> removeTrip(String reference);

  /// Retrieves flight booking details for the owner or via guest challenge.
  /// (Traveling_Safer_My_Bookings.md: Flight Bookings #1 & #2)
  Future<FlightBookingDetails> getFlightBookingDetails(
    String reference, {
    String? guestEmail,
    String? guestLastName,
  });

  /// Retrieves hotel booking details for the owner or via guest challenge.
  /// (Traveling_Safer_My_Bookings.md: Hotel Bookings #1 & #2)
  Future<HotelBookingDetails> getHotelBookingDetails(
    String reference, {
    String? guestEmail,
    String? guestLastName,
  });

  /// Releases eligible flight PNR for the booking owner.
  /// (Traveling_Safer_My_Bookings.md: Flight Bookings #3)
  Future<void> releaseFlightBooking(String reference);

  /// Requests auditable flight refund for the booking owner.
  /// (Traveling_Safer_My_Bookings.md: Flight Bookings #4)
  Future<Map<String, dynamic>> requestFlightRefund(
    String reference, {
    num? amount,
    String? reason,
  });

  /// Downloads flight invoice in PDF format.
  /// (Traveling_Safer_My_Bookings.md: Flight Bookings #5)
  Future<Uint8List> downloadFlightInvoice(String reference);

  /// Downloads flight ticket in PDF format.
  /// (Traveling_Safer_My_Bookings.md: Flight Bookings #6)
  Future<Uint8List> downloadFlightTicket(String reference);

  /// Requests hotel cancellation/refund for the booking owner.
  /// (Traveling_Safer_My_Bookings.md: Hotel Bookings #3)
  Future<void> cancelHotelBooking(String reference, {String? reason});

  /// Admin operation to retrieve customer bookings by customer ID.
  /// (Traveling_Safer_My_Bookings.md: Admin Booking Endpoints #1)
  Future<List<Trip>> getCustomerBookings(String customerId, {String? adminToken});
}
