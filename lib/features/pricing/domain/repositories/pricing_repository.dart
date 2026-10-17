import '../entities/coupon_validation.dart';

abstract interface class PricingRepository {
  Future<CouponValidation> validatePromoCode({
    required String code,
    String? contextToken,
    String productType = 'flight',
    num amount = 0,
    String currency = 'SAR',
    String? origin,
    String? destination,
    String? airlineCode,
  });

  Future<CouponValidation> validateCoupon(
    String code, {
    num amount = 0,
    String productType = 'flight',
    String? contextToken,
  });

  Future<Map<String, dynamic>> previewPrice({
    required String productType,
    required num basePrice,
    String currency = 'SAR',
    String? couponCode,
  });
}
