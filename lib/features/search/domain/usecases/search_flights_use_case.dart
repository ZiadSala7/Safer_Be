import '../entities/flight_offer.dart';
import '../entities/flight_search.dart';
import '../entities/flight_search_response.dart';
import '../repositories/travel_search_repository.dart';

class SearchFlightsUseCase {
  const SearchFlightsUseCase(this.repository);
  final TravelSearchRepository repository;

  Future<List<FlightOffer>> call(FlightSearch search) {
    return repository.flights(search);
  }

  Future<FlightSearchResponse> withMeta(FlightSearch search) {
    return repository.searchFlights(search);
  }
}
