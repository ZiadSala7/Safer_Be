import '../entities/coupon_validation.dart';

abstract interface class PricingRepository {
  Future<CouponValidation> validateCoupon(String code, {num amount = 0, String productType = 'flight'});
  Future<Map<String, dynamic>> previewPrice({
    required String productType,
    required num basePrice,
    String currency = 'SAR',
    String? couponCode,
  });
}
