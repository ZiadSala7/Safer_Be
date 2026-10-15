import '../../../../core/network/json_read.dart';
import 'app_currency.dart';
import 'flight_offer.dart';

class FlightSearchResponse {
  const FlightSearchResponse({
    required this.offers,
    this.searchId,
    this.supplier,
    this.journeyType,
    this.total,
  });

  final List<FlightOffer> offers;
  final String? searchId;
  final String? supplier;
  final int? journeyType;
  final int? total;

  factory FlightSearchResponse.fromJson(dynamic json) {
    final data = apiList(json).map(FlightOffer.fromJson).toList();
    final envelope = json is Map ? json : const {};
    final dataEnvelope = envelope['data'] is Map
        ? envelope['data'] as Map
        : envelope;
    final searchId = readText(dataEnvelope, [
      'search_id',
      'searchId',
    ], readText(envelope, ['search_id', 'searchId']));
    final supplier = readText(dataEnvelope, [
      'supplier',
    ], readText(envelope, ['supplier']));
    final journeyType = readNumber(dataEnvelope, [
      'journey_type',
      'journeyType',
    ]).toInt();
    final total = readNumber(dataEnvelope, [
      'total_available',
      'total',
    ]).toInt();

    return FlightSearchResponse(
      offers: data
          .map(
            (offer) => offer.copyWith(
              searchId: searchId.isEmpty ? offer.searchId : searchId,
              supplier: offer.supplier ?? (supplier.isEmpty ? null : supplier),
            ),
          )
          .toList(growable: false),
      searchId: searchId.isEmpty ? null : searchId,
      supplier: supplier.isEmpty ? null : supplier,
      journeyType: journeyType == 0 ? null : journeyType,
      total: total == 0 ? data.length : total,
    );
  }

  static const empty = FlightSearchResponse(offers: []);

  FlightSearchResponse convertedTo(String targetCurrency) {
    final target = targetCurrency.trim().toUpperCase();
    if (target.isEmpty) return this;
    final convertedOffers = offers.map((offer) {
      if (offer.currency.trim().toUpperCase() == target) return offer;
      final newPrice = AppCurrency.convert(
        offer.price,
        from: offer.currency,
        to: target,
      );
      return offer.copyWith(
        price: newPrice,
        currency: target,
      );
    }).toList(growable: false);

    return FlightSearchResponse(
      offers: convertedOffers,
      searchId: searchId,
      supplier: supplier,
      journeyType: journeyType,
      total: total,
    );
  }
}
