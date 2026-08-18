import '../../../../core/network/json_read.dart';

class HotelOffer {
  const HotelOffer({
    required this.code,
    required this.name,
    required this.location,
    required this.price,
    required this.currency,
    required this.rating,
    required this.imageUrl,
    required this.description,
  });

  final String code;
  final String name;
  final String location;
  final num price;
  final String currency;
  final num rating;
  final String imageUrl;
  final String description;

  num get totalPrice => price;

  factory HotelOffer.fromJson(Map<String, dynamic> json) {
    final images = json['images'] is List ? json['images'] as List : const [];
    Map? firstImage;
    for (final image in images) {
      if (image is Map) {
        firstImage = image;
        break;
      }
    }
    return HotelOffer(
      code: readText(json, ['hotel_code', 'hotelCode', 'code']),
      name: readText(json, ['hotel_name', 'hotelName', 'name'], 'Hotel'),
      location: readText(json, ['address', 'city_name', 'location']),
      price: readNumber(json, ['total_price', 'min_price', 'price']),
      currency: readText(json, ['currency', 'currency_code'], 'SAR'),
      rating: readNumber(json, ['star_rating', 'rating']),
      imageUrl: firstImage == null ? '' : readText(firstImage, ['url']),
      description: readText(json, ['description']),
    );
  }
}
