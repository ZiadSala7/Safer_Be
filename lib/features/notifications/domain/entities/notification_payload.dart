import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    this.bookingReference,
    this.productType,
    this.offerId,
    this.offerType,
    this.deepLink,
    this.title,
    this.body,
    this.rawData = const {},
  });

  static const String typeBookingRequestConfirmed = 'booking.request_confirmed';
  static const String typeBookingConfirmed = 'booking.confirmed';
  static const String typeFulfillmentFailed = 'fulfillment.failed';
  static const String typeRefundCompleted = 'refund.completed';
  static const String typeCustomerApprovalRequired = 'customer.approval_required';
  static const String typeOfferActivated = 'offer.activated';

  final String type;
  final String? bookingReference;
  final String? productType;
  final String? offerId;
  final String? offerType;
  final String? deepLink;
  final String? title;
  final String? body;
  final Map<String, dynamic> rawData;

  bool get isBookingEvent =>
      type == typeBookingRequestConfirmed ||
      type == typeBookingConfirmed ||
      type == typeFulfillmentFailed ||
      type == typeRefundCompleted ||
      type == typeCustomerApprovalRequired;

  bool get isApprovalEvent => type == typeCustomerApprovalRequired;

  bool get isOfferEvent => type == typeOfferActivated;

  bool get isHotel => productType?.toLowerCase() == 'hotel';

  bool get isFlight =>
      productType?.toLowerCase() == 'flight' ||
      (isBookingEvent && productType == null);

  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    return NotificationPayload.fromDataMap(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  factory NotificationPayload.fromDataMap(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final cleanData = data.map((key, value) => MapEntry(key, value?.toString() ?? ''));
    return NotificationPayload(
      type: cleanData['type'] ?? '',
      bookingReference: cleanData['booking_reference']?.isNotEmpty == true
          ? cleanData['booking_reference']
          : null,
      productType: cleanData['product_type']?.isNotEmpty == true
          ? cleanData['product_type']
          : null,
      offerId: cleanData['offer_id']?.isNotEmpty == true
          ? cleanData['offer_id']
          : null,
      offerType: cleanData['offer_type']?.isNotEmpty == true
          ? cleanData['offer_type']
          : null,
      deepLink: cleanData['deep_link']?.isNotEmpty == true
          ? cleanData['deep_link']
          : null,
      title: title,
      body: body,
      rawData: cleanData,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    if (bookingReference != null) 'booking_reference': bookingReference,
    if (productType != null) 'product_type': productType,
    if (offerId != null) 'offer_id': offerId,
    if (offerType != null) 'offer_type': offerType,
    if (deepLink != null) 'deep_link': deepLink,
    if (title != null) 'title': title,
    if (body != null) 'body': body,
  };
}
