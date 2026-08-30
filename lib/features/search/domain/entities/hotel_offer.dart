import '../../../../core/network/json_read.dart';

class HotelOffer {
  const HotelOffer({
    required this.code,
    required this.name,
    required this.supplier,
    this.ratePlanCode = '',
    required this.location,
    required this.price,
    required this.currency,
    required this.rating,
    required this.imageUrl,
    required this.description,
    this.amenities = const [],
    this.rawJson,
  });

  final String code;
  final String name;
  final String supplier;
  final String ratePlanCode;
  final String location;
  final num price;
  final String currency;
  final num rating;
  final String imageUrl;
  final String description;
  final List<String> amenities;
  final Map<String, dynamic>? rawJson;

  num get totalPrice => price;

  factory HotelOffer.fromJson(Map<String, dynamic> json) {
    String image = '';
    if (json['images'] is List) {
      final images = json['images'] as List;
      for (final item in images) {
        if (item is Map) {
          image = readText(item, ['url', 'src', 'link']);
          if (image.isNotEmpty) break;
        } else if (item is String && item.isNotEmpty) {
          image = item;
          break;
        }
      }
    }
    if (image.isEmpty) {
      image = readText(json, [
        'image_url',
        'imageUrl',
        'image',
        'thumbnail',
        'hero_image',
      ]);
    }

    final List<String> amenityList = [];
    if (json['amenities'] is List) {
      for (final item in json['amenities'] as List) {
        if (item is String && item.isNotEmpty) {
          amenityList.add(item);
        } else if (item is Map) {
          final name = readText(item, ['name', 'title', 'code']);
          if (name.isNotEmpty) amenityList.add(name);
        }
      }
    } else if (json['facilities'] is List) {
      for (final item in json['facilities'] as List) {
        if (item is String && item.isNotEmpty) {
          amenityList.add(item);
        }
      }
    }

    return HotelOffer(
      code: readText(json, ['hotel_code', 'hotelCode', 'code', 'id']),
      name: readText(json, ['hotel_name', 'hotelName', 'name'], 'Hotel'),
      supplier: readText(json, ['supplier', 'provider'], 'juniper'),
      ratePlanCode: readText(json, [
        'rate_plan_code',
        'ratePlanCode',
        'rate_plan',
        'ratePlan',
      ]),
      location: readText(json, [
        'address',
        'city_name',
        'cityName',
        'city',
        'location',
        'country',
      ]),
      price: readNumber(json, ['min_price', 'total_price', 'price', 'amount']),
      currency: readText(json, ['currency', 'currency_code', 'currencyCode'], 'SAR'),
      rating: readNumber(json, ['star_rating', 'starRating', 'rating', 'stars']),
      imageUrl: image,
      description: readText(json, ['description', 'summary', 'about']),
      amenities: amenityList,
      rawJson: json,
    );
  }
}
