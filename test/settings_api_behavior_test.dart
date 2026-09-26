import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/utils/whatsapp_helper.dart';
import 'package:safer_be_project/features/home/presentation/widgets/home_website_sections.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_offer.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_offer.dart';
import 'package:safer_be_project/features/search/presentation/widgets/flight_offer_card.dart';
import 'package:safer_be_project/features/search/presentation/widgets/hotel_offer_card.dart';
import 'package:safer_be_project/features/settings/domain/entities/system_settings.dart';

void main() {
  group('Settings API Documentation (settings_api_documentation_updated.md) Tests', () {
    test('1. SystemSettings parses public endpoint and admin endpoint shapes accurately', () {
      // Public endpoint true (Normal Online Booking Mode)
      final publicTrue = SystemSettings.fromJson({
        'success': true,
        'data': {'show_payment_gateway_mobile': true},
      });
      expect(publicTrue.showPaymentGatewayMobile, isTrue);
      expect(publicTrue.isWhatsAppContactMode, isFalse);

      // Public endpoint false (WhatsApp Contact Mode)
      final publicFalse = SystemSettings.fromJson({
        'success': true,
        'data': {
          'show_payment_gateway_mobile': false,
          'pricing.support_code.sequence.2026': false,
        },
      });
      expect(publicFalse.showPaymentGatewayMobile, isFalse);
      expect(publicFalse.isWhatsAppContactMode, isTrue);

      // Admin endpoint list shape
      final adminList = SystemSettings.fromJson({
        'success': true,
        'data': [
          {
            'id': 1,
            'key': 'show_payment_gateway_mobile',
            'value': '0',
          }
        ],
      });
      expect(adminList.showPaymentGatewayMobile, isFalse);
      expect(adminList.isWhatsAppContactMode, isTrue);
    });

    test('2. AppWhatsAppHelper configures default official WhatsApp number', () {
      expect(AppWhatsAppHelper.defaultPhoneNumber, '966920011244');
      expect(AppWhatsAppHelper.defaultWaUrl, 'https://wa.me/966920011244');
    });

    testWidgets('3. FlightOfferCard hides price and shows WhatsApp indicator in WhatsApp Contact Mode',
        (tester) async {
      final offer = FlightOffer(
        id: 'FL-001',
        airline: 'Saudia',
        route: 'RUH → DXB',
        time: '10:00 AM',
        departureTime: DateTime(2026, 10, 1, 10, 0),
        arrivalTime: DateTime(2026, 10, 1, 12, 0),
        durationMinutes: 120,
        price: 550.0,
        currency: 'SAR',
        stops: 0,
        cabinClass: 'Economy',
        baggage: '1 piece',
        refundable: true,
        labels: const ['Best Value'],
      );

      final controller = AppController();
      controller.showPaymentGatewayMobile = false; // WhatsApp Contact Mode

      await tester.pumpWidget(
        AppControllerScope(
          notifier: controller,
          child: MaterialApp(
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: const [Locale('en'), Locale('ar')],
            locale: const Locale('en'),
            home: Scaffold(
              body: FlightOfferCard(offer: offer),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Price should be HIDDEN
      expect(find.text('550.00 SAR'), findsNothing);
      expect(find.text('per traveler'), findsNothing);

      // Flight details should REMAIN visible
      expect(find.text('Saudia'), findsOneWidget);

      // Inquire via WhatsApp should be SHOWN
      expect(find.text('Inquire via WhatsApp'), findsOneWidget);

      // Switch to Normal Booking Mode
      controller.setWhatsAppContactModeLocal(false);
      await tester.pumpAndSettle();

      // Price should now be SHOWN
      expect(find.text('550.00 SAR'), findsOneWidget);
      expect(find.text('per traveler'), findsOneWidget);
    });

    testWidgets('4. HotelOfferCard hides price and shows WhatsApp indicator in WhatsApp Contact Mode',
        (tester) async {
      final hotel = HotelOffer(
        code: 'HT-001',
        name: 'Grand Hyatt Riyadh',
        supplier: 'juniper',
        location: 'Olaya, Riyadh',
        rating: 5,
        price: 950.0,
        currency: 'SAR',
        imageUrl: '',
        description: 'Luxury hotel',
      );

      final controller = AppController();
      controller.showPaymentGatewayMobile = false; // WhatsApp Contact Mode

      await tester.pumpWidget(
        AppControllerScope(
          notifier: controller,
          child: MaterialApp(
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: const [Locale('en'), Locale('ar')],
            locale: const Locale('en'),
            home: Scaffold(
              body: HotelOfferCard(offer: hotel),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Price should be HIDDEN
      expect(find.text('950.00 SAR'), findsNothing);

      // Hotel details should REMAIN visible
      expect(find.text('Grand Hyatt Riyadh'), findsOneWidget);

      // Inquire via WhatsApp should be SHOWN
      expect(find.text('Inquire via WhatsApp'), findsWidgets);

      // Switch to Normal Booking Mode
      controller.setWhatsAppContactModeLocal(false);
      await tester.pumpAndSettle();

      // Price should now be SHOWN
      expect(find.text('950.00 SAR'), findsOneWidget);
    });

    testWidgets('5. PopularRoutesSection hides price hints when in WhatsApp Contact Mode',
        (tester) async {
      final controller = AppController();
      controller.showPaymentGatewayMobile = false; // WhatsApp Contact Mode

      await tester.pumpWidget(
        AppControllerScope(
          notifier: controller,
          child: const MaterialApp(
            localizationsDelegates: [AppLocalizations.delegate],
            supportedLocales: [Locale('en'), Locale('ar')],
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(child: PopularRoutesSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Price hints should be HIDDEN
      expect(find.text('380 SAR'), findsNothing);
      expect(find.text('420 SAR'), findsNothing);

      // Route codes remain VISIBLE
      expect(find.text('RUH'), findsWidgets);
      expect(find.text('DXB'), findsWidgets);
    });
  });
}
