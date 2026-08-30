import '../../../../core/network/json_read.dart';

class HotelRoom {
  const HotelRoom({
    this.roomId,
    required this.code,
    this.roomTypeCode,
    required this.name,
    required this.mealPlan,
    required this.price,
    this.basePrice,
    required this.currency,
    required this.refundable,
    required this.cancellationPolicy,
    this.rawJson,
  });

  final String? roomId;
  final String code;
  final String? roomTypeCode;
  final String name;
  final String mealPlan;
  final num price;
  final num? basePrice;
  final String currency;
  final bool refundable;
  final String cancellationPolicy;
  final Map<String, dynamic>? rawJson;

  factory HotelRoom.fromJson(Map<String, dynamic> json) {
    final nestedPrice = json['price'];
    final priceSource = nestedPrice is Map ? nestedPrice : json;
    final rId = readText(json, ['room_id', 'roomId', 'id']);
    final rCode = readText(json, [
      'room_code',
      'roomCode',
      'code',
      'rate_plan_code',
      'ratePlanCode',
    ]);
    final rTypeCode = readText(json, [
      'room_type_code',
      'roomTypeCode',
      'room_code',
      'roomCode',
    ]);

    return HotelRoom(
      roomId: rId.isNotEmpty ? rId : (rCode.isNotEmpty ? rCode : null),
      code: rCode.isNotEmpty ? rCode : (rId.isNotEmpty ? rId : 'STD'),
      roomTypeCode: rTypeCode.isNotEmpty ? rTypeCode : null,
      name: readText(json, [
        'room_name',
        'roomName',
        'name',
        'room_type',
        'roomType',
      ], 'Standard Room'),
      mealPlan: readText(json, [
        'meal_plan',
        'mealPlan',
        'board_code',
        'boardCode',
        'board',
        'meal',
      ], 'Room Only'),
      price: readNumber(priceSource, [
        'total_price',
        'totalPrice',
        'amount',
        'price',
        'total',
      ]),
      basePrice: readNumber(priceSource, [
        'base_price',
        'basePrice',
        'total_price',
        'price',
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
      rawJson: json,
    );
  }
}
