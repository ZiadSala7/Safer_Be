import '../entities/airport.dart';
import '../entities/checkout_result.dart';
import '../entities/flight_booking.dart';
import '../entities/flight_offer.dart';
import '../entities/flight_search.dart';
import '../entities/flight_search_response.dart';
import '../entities/hotel_booking.dart';
import '../entities/hotel_booking_details.dart';
import '../entities/hotel_offer.dart';
import '../entities/hotel_room.dart';
import '../entities/hotel_search.dart';
import '../entities/travel_city.dart';

abstract interface class TravelSearchRepository {
  Future<List<Airport>> airports(String query);
  Future<Airport?> airportByCode(String code);
  Future<List<Airport>> nearbyAirports({
    required double latitude,
    required double longitude,
    int radius = 100,
    int limit = 10,
  });
  Future<List<Map<String, dynamic>>> destinationsAutocomplete(
    String query, {
    int limit = 20,
  });
  Future<List<Map<String, dynamic>>> airportsSuggest(
    String query, {
    int limit = 20,
  });
  Future<List<TravelCity>> cities(String query);
  Future<List<Map<String, dynamic>>> currencies();
  Future<List<FlightOffer>> flights(FlightSearch search);
  Future<FlightSearchResponse> searchFlights(FlightSearch search);
  Future<List<FlightOffer>> cheapestFlights(FlightSearch search, {int limit});
  Future<List<FlightOffer>> fastestFlights(FlightSearch search, {int limit});
  Future<Map<String, dynamic>> fareQuote({
    required String resultIndex,
    String? referenceIndex,
    String? searchId,
    String supplier = 'tbo',
    String currency = 'USD',
  });
  Future<List<Map<String, dynamic>>> zones();
  Future<Map<String, dynamic>> detectZone({
    double? latitude,
    double? longitude,
    String? airportCode,
  });
  Future<List<Map<String, dynamic>>> flightTypes();
  Future<List<Map<String, dynamic>>> airlines({String? search, int limit = 50});
  Future<List<Map<String, dynamic>>> topHotelDestinations({
    String? countryCode,
  });
  Future<List<HotelOffer>> hotels(HotelSearch search);
  Future<List<HotelRoom>> hotelRooms({
    required HotelOffer offer,
    required HotelSearch search,
  });
  Future<HotelBookingResult> bookHotel(HotelBookingRequest request);
  Future<FlightBookingResult> bookFlight(FlightBookingRequest request);
  Future<CheckoutResult> initiateFlightCheckout(FlightBookingRequest request);
  Future<CheckoutResult> initiateHotelCheckout(HotelBookingRequest request);
  Future<Map<String, dynamic>> getFlightBooking(String reference);
  Future<void> releaseFlightBooking(String reference);
  Future<Map<String, dynamic>> ticketFlight({
    String? pnr,
    String? bookingReference,
  });
  Future<Map<String, dynamic>> refundFlightBooking(String reference);
  Future<Map<String, dynamic>> getFlightTicket(String reference);
  Future<Map<String, dynamic>> getHotelBooking(String reference);
  Future<HotelBookingDetails> getHotelBookingDetails(String reference);
  Future<HotelPaymentCallbackResult> verifyHotelPaymentCallback(String paymentId);
  Future<HotelPaymentCallbackResult> verifyFlightPaymentCallback(String paymentId);
  Future<void> cancelHotelBooking(String reference, [String? reason]);
}
