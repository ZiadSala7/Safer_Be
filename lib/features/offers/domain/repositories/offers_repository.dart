import '../../../home/domain/entities/travel_content.dart';

abstract interface class OffersRepository {
  List<TravelOffer> getAll();
}
