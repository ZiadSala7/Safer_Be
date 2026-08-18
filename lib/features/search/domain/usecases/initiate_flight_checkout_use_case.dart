import '../entities/checkout_result.dart';
import '../entities/flight_booking.dart';
import '../repositories/travel_search_repository.dart';

class InitiateFlightCheckoutUseCase {
  const InitiateFlightCheckoutUseCase(this.repository);
  final TravelSearchRepository repository;

  Future<CheckoutResult> call(FlightBookingRequest request) {
    return repository.initiateFlightCheckout(request);
  }
}
