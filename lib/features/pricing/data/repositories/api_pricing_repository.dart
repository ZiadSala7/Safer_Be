import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_read.dart';
import '../../domain/entities/coupon_validation.dart';
import '../../domain/repositories/pricing_repository.dart';

class ApiPricingRepository implements PricingRepository {
  ApiPricingRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<CouponValidation> validatePromoCode({
    required String code,
    String? contextToken,
    String productType = 'flight',
    num amount = 0,
    String currency = 'SAR',
    String? origin,
    String? destination,
    String? airlineCode,
  }) async {
    final body = <String, dynamic>{
      'code': code.trim().toUpperCase(),
    };
    if (contextToken != null && contextToken.trim().isNotEmpty) {
      body['context_token'] = contextToken.trim();
    } else {
      body['product_type'] = productType;
      if (amount > 0) body['amount'] = amount;
      if (currency.isNotEmpty) body['currency'] = currency;
      if (origin != null && origin.isNotEmpty) body['origin'] = origin;
      if (destination != null && destination.isNotEmpty) {
        body['destination'] = destination;
      }
      if (airlineCode != null && airlineCode.isNotEmpty) {
        body['airline_code'] = airlineCode;
      }
    }

    try {
      final response = await _client.post(
        '/promo-codes/validate',
        body: body,
      );
      return CouponValidation.fromJson(response);
    } on ApiException catch (e) {
      // 422 error response includes promo invalid details
      return CouponValidation(
        isValid: false,
        code: code,
        discountAmount: 0,
        message: e.message,
      );
    }
  }

  @override
  Future<CouponValidation> validateCoupon(
    String code, {
    num amount = 0,
    String productType = 'flight',
    String? contextToken,
  }) {
    return validatePromoCode(
      code: code,
      contextToken: contextToken,
      amount: amount,
      productType: productType,
    );
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
