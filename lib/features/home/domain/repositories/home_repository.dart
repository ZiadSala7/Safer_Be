import '../entities/travel_content.dart';

abstract interface class HomeRepository {
  List<TravelOffer> get offers;
  List<Destination> get destinations;
  List<QuickService> get services;
}
