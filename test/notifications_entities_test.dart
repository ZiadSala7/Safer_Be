import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/features/notifications/domain/entities/device_token.dart';
import 'package:safer_be_project/features/notifications/domain/entities/notification_payload.dart';

void main() {
  group('DeviceToken Entity Tests', () {
    test('parses json from POST/GET /customer/devices correctly', () {
      final json = {
        'id': 42,
        'platform': 'android',
        'device_id': 'hw-install-uuid-12345',
        'app_version': '1.1.0',
        'token_hint': 'fcm_tok...abcd',
        'last_used_at': '2026-09-19T20:00:00Z',
        'created_at': '2026-09-19T19:00:00Z',
      };

      final token = DeviceToken.fromJson(json);

      expect(token.id, 42);
      expect(token.platform, 'android');
      expect(token.deviceId, 'hw-install-uuid-12345');
      expect(token.appVersion, '1.1.0');
      expect(token.tokenHint, 'fcm_tok...abcd');
      expect(token.lastUsedAt, '2026-09-19T20:00:00Z');
      expect(token.createdAt, '2026-09-19T19:00:00Z');

      final map = token.toJson();
      expect(map['id'], 42);
      expect(map['platform'], 'android');
      expect(map['device_id'], 'hw-install-uuid-12345');
    });

    test('handles fallback defaults gracefully', () {
      final token = DeviceToken.fromJson({'id': 1});
      expect(token.id, 1);
      expect(token.platform, 'android');
      expect(token.deviceId, isNull);
      expect(token.appVersion, isNull);
    });
  });

  group('NotificationPayload Entity Tests (All 6 Documented Types)', () {
    test('type: booking.request_confirmed with flight details', () {
      final payload = NotificationPayload.fromDataMap({
        'type': 'booking.request_confirmed',
        'booking_reference': 'SB-FLIGHT-9876',
        'product_type': 'flight',
      }, title: 'Booking Request Confirmed', body: 'We received your flight booking request.');

      expect(payload.type, NotificationPayload.typeBookingRequestConfirmed);
      expect(payload.bookingReference, 'SB-FLIGHT-9876');
      expect(payload.productType, 'flight');
      expect(payload.isBookingEvent, isTrue);
      expect(payload.isFlight, isTrue);
      expect(payload.isHotel, isFalse);
      expect(payload.isOfferEvent, isFalse);
      expect(payload.title, 'Booking Request Confirmed');
    });

    test('type: booking.confirmed with hotel details', () {
      final payload = NotificationPayload.fromDataMap({
        'type': 'booking.confirmed',
        'booking_reference': 'SB-HOTEL-5544',
        'product_type': 'hotel',
      });

      expect(payload.type, NotificationPayload.typeBookingConfirmed);
      expect(payload.bookingReference, 'SB-HOTEL-5544');
      expect(payload.productType, 'hotel');
      expect(payload.isBookingEvent, isTrue);
      expect(payload.isHotel, isTrue);
      expect(payload.isFlight, isFalse);
    });

    test('type: fulfillment.failed routes as booking event', () {
      final payload = NotificationPayload.fromDataMap({
        'type': 'fulfillment.failed',
        'booking_reference': 'SB-FLIGHT-1122',
        'product_type': 'flight',
      });

      expect(payload.type, NotificationPayload.typeFulfillmentFailed);
      expect(payload.isBookingEvent, isTrue);
      expect(payload.bookingReference, 'SB-FLIGHT-1122');
    });

    test('type: refund.completed routes as booking event', () {
      final payload = NotificationPayload.fromDataMap({
        'type': 'refund.completed',
        'booking_reference': 'SB-HOTEL-9900',
        'product_type': 'hotel',
      });

      expect(payload.type, NotificationPayload.typeRefundCompleted);
      expect(payload.isBookingEvent, isTrue);
      expect(payload.isHotel, isTrue);
    });

    test('type: customer.approval_required triggers approval event', () {
      final payload = NotificationPayload.fromDataMap({
        'type': 'customer.approval_required',
        'booking_reference': 'SB-FLIGHT-7788',
        'product_type': 'flight',
      });

      expect(payload.type, NotificationPayload.typeCustomerApprovalRequired);
      expect(payload.isBookingEvent, isTrue);
      expect(payload.isApprovalEvent, isTrue);
      expect(payload.bookingReference, 'SB-FLIGHT-7788');
    });

    test('type: offer.activated parses offer_id and offer_type', () {
      final payload = NotificationPayload.fromDataMap({
        'type': 'offer.activated',
        'offer_id': '101',
        'offer_type': 'destination',
      }, title: 'New Special Offer!', body: 'Check out 20% off flights to Dubai');

      expect(payload.type, NotificationPayload.typeOfferActivated);
      expect(payload.offerId, '101');
      expect(payload.offerType, 'destination');
      expect(payload.isOfferEvent, isTrue);
      expect(payload.isBookingEvent, isFalse);
    });

    test('string-only data enforcement: converts non-string primitives safely', () {
      final payload = NotificationPayload.fromDataMap({
        'type': 'offer.activated',
        'offer_id': 202,
        'product_type': 'flight',
      });

      expect(payload.offerId, '202');
      expect(payload.productType, 'flight');
    });
  });
}
