import '../../../../core/network/json_read.dart';

class HotelRoom {
  const HotelRoom({
    required this.code,
    required this.name,
    required this.mealPlan,
    required this.price,
    required this.currency,
    required this.refundable,
    required this.cancellationPolicy,
  });

  final String code;
  final String name;
  final String mealPlan;
  final num price;
  final String currency;
  final bool refundable;
  final String cancellationPolicy;

  factory HotelRoom.fromJson(Map<String, dynamic> json) {
    final nestedPrice = json['price'];
    final priceSource = nestedPrice is Map ? nestedPrice : json;
    return HotelRoom(
      code: readText(json, [
        'room_code',
        'roomCode',
        'code',
        'rate_plan_code',
        'ratePlanCode',
      ]),
      name: readText(json, [
        'room_name',
        'roomName',
        'name',
        'room_type',
        'roomType',
      ], 'Standard room'),
      mealPlan: readText(json, [
        'meal_plan',
        'mealPlan',
        'board_code',
        'boardCode',
        'board',
      ], 'BB'),
      price: readNumber(priceSource, [
        'total_price',
        'totalPrice',
        'amount',
        'price',
        'total',
      ]),
      currency: readText(priceSource, ['currency', 'currency_code'], 'SAR'),
      refundable:
          json['refundable'] == true ||
          json['is_refundable'] == true ||
          json['isRefundable'] == true,
      cancellationPolicy: readText(json, [
        'cancellation_policy',
        'cancellationPolicy',
        'policy',
      ]),
    );
  }
}
