import '../../../../core/network/json_read.dart';

class CouponValidation {
  const CouponValidation({
    required this.isValid,
    required this.code,
    required this.discountAmount,
    this.discountRequested,
    this.discountApplied,
    this.clampReason,
    this.clampMessage,
    this.amountBefore,
    this.amountAfter,
    this.currency,
    this.isEstimate = false,
    this.expiresAt,
    required this.message,
    this.messageEn,
  });

  final bool isValid;
  final String code;
  final num discountAmount;
  final num? discountRequested;
  final num? discountApplied;
  final String? clampReason;
  final String? clampMessage;
  final num? amountBefore;
  final num? amountAfter;
  final String? currency;
  final bool isEstimate;
  final String? expiresAt;
  final String message;
  final String? messageEn;

  factory CouponValidation.fromJson(dynamic json) {
    final data = apiData(json);
    final map = data is Map ? data : (json is Map ? json : const {});
    final applied = readNumber(map, [
      'discount_applied',
      'discount_amount',
      'discount',
      'amount',
    ]);
    final req = readNumber(map, ['discount_requested']);
    final clampReason = map['clamp_reason']?.toString();
    final clampMessage = map['clamp_message']?.toString();
    final amtBefore = readNumber(map, ['amount_before', 'original_amount']);
    final amtAfter = readNumber(map, ['amount_after', 'final_amount']);
    final isEst = map['is_estimate'] == true;

    return CouponValidation(
      isValid: map['is_valid'] == true ||
          map['valid'] == true ||
          (json is Map && json['success'] == true),
      code: readText(map, ['code', 'coupon_code']),
      discountAmount: applied,
      discountRequested: req > 0 ? req : null,
      discountApplied: applied > 0 ? applied : null,
      clampReason:
          clampReason != null && clampReason.isNotEmpty ? clampReason : null,
      clampMessage: clampMessage != null && clampMessage.isNotEmpty
          ? clampMessage
          : null,
      amountBefore: amtBefore > 0 ? amtBefore : null,
      amountAfter: amtAfter > 0 ? amtAfter : null,
      currency: readText(map, ['currency']),
      isEstimate: isEst,
      expiresAt: map['expires_at']?.toString(),
      message: readText(
        map,
        ['message'],
        applied > 0 ? 'Coupon validated successfully.' : 'Invalid coupon',
      ),
      messageEn: map['message_en']?.toString(),
    );
  }
}
