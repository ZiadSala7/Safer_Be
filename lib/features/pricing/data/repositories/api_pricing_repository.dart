import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_read.dart';
import '../../domain/entities/coupon_validation.dart';
import '../../domain/repositories/pricing_repository.dart';

class ApiPricingRepository implements PricingRepository {
  ApiPricingRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<CouponValidation> validateCoupon(
    String code, {
    num amount = 0,
    String productType = 'flight',
  }) async {
    final response = await _client.post(
      '/pricing/coupons/validate',
      body: {
        'code': code,
        'amount': amount,
        'product_type': productType,
      },
    );
    return CouponValidation.fromJson(response);
  }

  @override
  Future<Map<String, dynamic>> previewPrice({
    required String productType,
    required num basePrice,
    String currency = 'SAR',
    String? couponCode,
  }) async {
    final response = await _client.post(
      '/pricing/preview',
      body: {
        'product_type': productType,
        'base_price': basePrice,
        'currency': currency,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      },
    );
    final data = apiData(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }
}
