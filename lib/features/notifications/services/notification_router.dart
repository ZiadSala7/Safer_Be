import 'package:flutter/material.dart';

import '../../offers/presentation/pages/offers_page.dart';
import '../../search/presentation/pages/hotel_booking_status_page.dart';
import '../../trips/presentation/pages/flight_booking_details_page.dart';
import '../domain/entities/notification_payload.dart';

class NotificationRouter {
  const NotificationRouter();

  static void route(
    NotificationPayload payload, {
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    final state = navigatorKey.currentState;
    if (state == null) {
      debugPrint('[NotificationRouter] NavigatorState is not ready yet');
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    debugPrint('[NotificationRouter] Routing event type: ${payload.type} ref: ${payload.bookingReference} offer: ${payload.offerId}');

    if (payload.isBookingEvent) {
      final ref = payload.bookingReference;
      if (ref != null && ref.isNotEmpty) {
        if (payload.isHotel) {
          state.push(
            MaterialPageRoute<void>(
              builder: (_) => HotelBookingStatusPage(bookingReference: ref),
            ),
          );
        } else {
          state.push(
            MaterialPageRoute<void>(
              builder: (_) => FlightBookingDetailsPage(bookingReference: ref),
            ),
          );
        }
        return;
      }
    }

    if (payload.isOfferEvent) {
      state.push(
        MaterialPageRoute<void>(
          builder: (_) => OffersPage(
            initialOfferId: payload.offerId,
            isStandalone: true,
          ),
        ),
      );
      return;
    }

    debugPrint('[NotificationRouter] Unhandled or general payload type: ${payload.type}');
  }
}
