import '../../../home/data/repositories/local_home_repository.dart';
import '../../../home/domain/entities/travel_content.dart';
import '../../domain/repositories/offers_repository.dart';

class LocalOffersRepository implements OffersRepository {
  final _home = LocalHomeRepository();
  @override
  List<TravelOffer> getAll() => _home.offers;
}
