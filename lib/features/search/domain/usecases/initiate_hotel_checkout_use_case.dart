import '../entities/checkout_result.dart';
import '../entities/hotel_booking.dart';
import '../repositories/travel_search_repository.dart';

class InitiateHotelCheckoutUseCase {
  const InitiateHotelCheckoutUseCase(this.repository);
  final TravelSearchRepository repository;

  Future<CheckoutResult> call(HotelBookingRequest request) {
    return repository.initiateHotelCheckout(request);
  }
}
