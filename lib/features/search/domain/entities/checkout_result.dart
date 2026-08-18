import '../../../../core/network/json_read.dart';

class CheckoutResult {
  const CheckoutResult({
    required this.bookingReference,
    required this.paymentUrl,
    required this.message,
    this.success = true,
  });

  final String bookingReference;
  final String paymentUrl;
  final String message;
  final bool success;

  factory CheckoutResult.fromJson(dynamic json) {
    final data = apiData(json);
    final map = data is Map ? data : (json is Map ? json : const {});
    return CheckoutResult(
      bookingReference: readText(map, [
        'booking_reference',
        'bookingReference',
        'reference',
      ]),
      paymentUrl: readText(map, ['payment_url', 'paymentUrl']),
      message: readText(
        json is Map ? json : map,
        ['message'],
        'Checkout initiated successfully.',
      ),
      success: json is Map ? (json['success'] == true) : true,
    );
  }
}
