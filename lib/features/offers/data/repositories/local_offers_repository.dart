import '../../../home/domain/entities/travel_content.dart';
import '../../domain/entities/marketing_offer.dart';
import '../../domain/repositories/offers_repository.dart';

class LocalOffersRepository implements OffersRepository {
  @override
  List<TravelOffer> getAll() => const [];

  @override
  Future<List<MarketingOffer>> getAvailableOffers({bool forceRefresh = false}) async {
    return const [];
  }
}
