import '../../../../core/network/json_read.dart';

class CouponValidation {
  const CouponValidation({
    required this.isValid,
    required this.code,
    required this.discountAmount,
    required this.message,
  });

  final bool isValid;
  final String code;
  final num discountAmount;
  final String message;

  factory CouponValidation.fromJson(dynamic json) {
    final data = apiData(json);
    final map = data is Map ? data : (json is Map ? json : const {});
    return CouponValidation(
      isValid: map['is_valid'] == true || map['valid'] == true || (json is Map && json['success'] == true),
      code: readText(map, ['code', 'coupon_code']),
      discountAmount: readNumber(map, ['discount_amount', 'discount', 'amount']),
      message: readText(map, ['message'], 'Coupon validated successfully.'),
    );
  }
}
