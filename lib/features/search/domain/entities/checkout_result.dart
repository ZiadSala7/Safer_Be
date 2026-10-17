import '../../../../core/network/json_read.dart';

class CheckoutResult {
  const CheckoutResult({
    required this.bookingReference,
    required this.paymentUrl,
    required this.message,
    this.success = true,
    this.amountBefore,
    this.amountAfter,
    this.discountRequested,
    this.discountApplied,
    this.clampReason,
    this.discountChanged = false,
    this.currency,
  });

  final String bookingReference;
  final String paymentUrl;
  final String message;
  final bool success;
  final num? amountBefore;
  final num? amountAfter;
  final num? discountRequested;
  final num? discountApplied;
  final String? clampReason;
  final bool discountChanged;
  final String? currency;

  factory CheckoutResult.fromJson(dynamic json) {
    final data = apiData(json);
    final map = data is Map ? data : (json is Map ? json : const {});
    final rootMap = json is Map ? json : map;
    return CheckoutResult(
      bookingReference: readText(map, [
        'booking_reference',
        'bookingReference',
        'reference',
      ]),
      paymentUrl: readText(map, ['payment_url', 'paymentUrl']),
      message: readText(
        rootMap,
        ['message'],
        'Checkout initiated successfully.',
      ),
      success: json is Map ? (json['success'] == true) : true,
      amountBefore: readNumber(map, ['amount_before', 'original_amount']) > 0
          ? readNumber(map, ['amount_before', 'original_amount'])
          : null,
      amountAfter: readNumber(map, ['amount_after', 'final_amount']) > 0
          ? readNumber(map, ['amount_after', 'final_amount'])
          : null,
      discountRequested: readNumber(map, ['discount_requested']) > 0
          ? readNumber(map, ['discount_requested'])
          : null,
      discountApplied: readNumber(map, ['discount_applied']) > 0
          ? readNumber(map, ['discount_applied'])
          : null,
      clampReason: map['clamp_reason']?.toString(),
      discountChanged: map['discount_changed'] == true ||
          rootMap['discount_changed'] == true,
      currency: readText(map, ['currency']),
    );
  }
}
