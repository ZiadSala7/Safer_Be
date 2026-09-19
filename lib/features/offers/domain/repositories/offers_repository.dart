import '../../../home/domain/entities/travel_content.dart';
import '../entities/marketing_offer.dart';

abstract interface class OffersRepository {
  /// Fetches available marketing offers from GET /api/v1/offers/available.
  Future<List<MarketingOffer>> getAvailableOffers({bool forceRefresh = false});

  /// Synchronous fallback / legacy access to offers.
  List<TravelOffer> getAll();
}
