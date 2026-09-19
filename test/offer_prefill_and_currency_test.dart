import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/theme/app_theme.dart';
import 'package:safer_be_project/features/home/domain/entities/travel_content.dart';
import 'package:safer_be_project/features/offers/domain/utils/offer_destination_resolver.dart';
import 'package:safer_be_project/features/search/domain/entities/app_currency.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_search.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_search.dart';
import 'package:safer_be_project/features/search/presentation/pages/flight_results_page.dart';
import 'package:safer_be_project/features/search/presentation/pages/hotel_results_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OfferDestinationResolver Tests', () {
    test('resolves Cairo hotel offer in Arabic', () {
      const offer = TravelOffer(
        titleKey: 'فندق القاهرة',
        subtitleKey: 'خصم 20% على فنادق القاهرة لفترة محدودة',
        code: 'CAIRO20',
        image: '/storage/offers/cairo.png',
        discount: 20,
        category: 'hotels',
      );

      final prefill = OfferDestinationResolver.resolve(offer);
      expect(prefill.bookingType, OfferBookingType.hotel);
      expect(prefill.city.name, 'Cairo');
      expect(prefill.city.code, 'CAI');
      expect(prefill.city.country, 'Egypt');
      expect(prefill.promoCode, 'CAIRO20');
      expect(prefill.hotelName, 'فندق القاهرة');
    });

    test('resolves Cairo hotel offer in English', () {
      const offer = TravelOffer(
        titleKey: 'Cairo Hotel Special Deal',
        subtitleKey: 'Save 15% on all bookings in Cairo',
        code: 'CAI15',
        image: 'https://example.com/cairo.jpg',
        discount: 15,
        category: 'hotel',
      );

      final prefill = OfferDestinationResolver.resolve(offer);
      expect(prefill.bookingType, OfferBookingType.hotel);
      expect(prefill.city.name, 'Cairo');
      expect(prefill.city.code, 'CAI');
      expect(prefill.promoCode, 'CAI15');
    });

    test('resolves Dubai flight offer with DXB destination', () {
      const offer = TravelOffer(
        titleKey: 'رحلات دبي الصيفية',
        subtitleKey: 'خصم 15% على جميع الرحلات إلى دبي DXB',
        code: 'DXB15',
        image: 'assets/images/destinations/dubai.jpg',
        discount: 15,
        category: 'flights',
      );

      final prefill = OfferDestinationResolver.resolve(offer);
      expect(prefill.bookingType, OfferBookingType.flight);
      expect(prefill.destinationAirport.code, 'DXB');
      expect(prefill.destinationAirport.city, 'Dubai');
      expect(prefill.promoCode, 'DXB15');
    });

    test('resolves offer condition with destination code', () {
      const offer = TravelOffer(
        titleKey: 'عرض خاص',
        subtitleKey: 'عرض على الإقامة الفندقية',
        code: 'SPECIAL',
        image: 'assets/images/destinations/alula.jpg',
        discount: 10,
        category: 'hotels',
        conditions: [
          OfferCondition(
            conditionType: 'destination',
            conditionValue: 'CAI',
          ),
        ],
      );

      final prefill = OfferDestinationResolver.resolve(offer);
      expect(prefill.bookingType, OfferBookingType.hotel);
      expect(prefill.city.code, 'CAI');
      expect(prefill.city.name, 'Cairo');
    });
  });

  group('Currency Switch & Live Refetch Payload Tests', () {
    test('HotelSearch copyWith updates currency and serializes to JSON correctly', () {
      final initial = HotelSearch(
        cityCode: 'CAI',
        checkIn: DateTime(2026, 10, 1),
        checkOut: DateTime(2026, 10, 5),
        currency: 'SAR',
      );

      expect(initial.toJson()['currency'], 'SAR');

      // User changes currency to USD
      final updatedUSD = initial.copyWith(currency: 'USD');
      expect(updatedUSD.currency, 'USD');
      expect(updatedUSD.toJson()['currency'], 'USD');

      // User changes currency to EGP
      final updatedEGP = initial.copyWith(currency: 'EGP');
      expect(updatedEGP.currency, 'EGP');
      expect(updatedEGP.toJson()['currency'], 'EGP');
    });

    test('FlightSearch copyWith updates currency and serializes correctly', () {
      final initial = FlightSearch(
        origin: 'RUH',
        destination: 'CAI',
        departure: DateTime(2026, 10, 1),
        currency: 'SAR',
      );

      expect(initial.toJson()['currency'], 'SAR');
      expect(initial.toJson()['Currency'], 'SAR');

      // User changes currency to EUR
      final updatedEUR = initial.copyWith(currency: 'EUR');
      expect(updatedEUR.currency, 'EUR');
      expect(updatedEUR.toJson()['currency'], 'EUR');
      expect(updatedEUR.toJson()['Currency'], 'EUR');

      // User changes currency to USD
      final updatedUSD = initial.copyWith(currency: 'USD');
      expect(updatedUSD.currency, 'USD');
      expect(updatedUSD.toJson()['currency'], 'USD');
    });

    test('AppCurrency lists and localization operate properly', () {
      final sar = AppCurrency.fromCode('SAR');
      expect(sar.code, 'SAR');
      expect(sar.localizedName('en'), 'Saudi Riyal');
      expect(sar.localizedName('ar'), 'ريال سعودي');
      expect(sar.symbol, 'ر.س');

      final usd = AppCurrency.fromCode('USD');
      expect(usd.code, 'USD');
      expect(usd.localizedName('en'), 'US Dollar');
      expect(usd.symbol, '\$');

      final egp = AppCurrency.fromCode('EGP');
      expect(egp.code, 'EGP');
      expect(egp.localizedName('ar'), 'جنيه مصري');
      expect(egp.symbol, 'ج.م');
    });

    test('AppCurrency parses API JSON from /currencies endpoint', () {
      final json = {
        'id': 1,
        'code': 'USD',
        'name': 'US Dollar',
        'symbol': '\$',
        'decimal_precision': 2,
        'is_default': true,
      };

      final currency = AppCurrency.fromJson(json);
      expect(currency.code, 'USD');
      expect(currency.name, 'US Dollar');
      expect(currency.symbol, '\$');
      expect(currency.isDefault, isTrue);
    });
  });

  group('Responsive Results Header AppBar Tests (Zero Overflow)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget buildTestApp({
      required Widget child,
      required Size size,
      Locale locale = const Locale('ar'),
    }) {
      final controller = AppController()..locale = locale;
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: AppControllerScope(
          notifier: controller,
          child: MaterialApp(
            locale: locale,
            theme: AppTheme.light(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: child,
          ),
        ),
      );
    }

    testWidgets(
      'HotelResultsPage renders on narrow 360px and 320px screens without RenderFlex overflow',
      (tester) async {
        final search = HotelSearch(
          cityCode: 'CAI',
          checkIn: DateTime(2026, 10, 1),
          checkOut: DateTime(2026, 10, 5),
          currency: 'USD',
          adults: 2,
          children: 1,
          rooms: 1,
        );

        for (final width in [360.0, 320.0]) {
          for (final locale in [const Locale('ar'), const Locale('en')]) {
            tester.view.physicalSize = Size(width, 700);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(
              buildTestApp(
                child: HotelResultsPage(search: search),
                size: Size(width, 700),
                locale: locale,
              ),
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets(
      'FlightResultsPage renders on narrow 360px and 320px screens without RenderFlex overflow',
      (tester) async {
        final search = FlightSearch(
          origin: 'RUH',
          destination: 'CAI',
          departure: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 8),
          currency: 'SAR',
          adults: 2,
          children: 1,
          infants: 0,
          cabinClass: 1,
        );

        for (final width in [360.0, 320.0]) {
          for (final locale in [const Locale('ar'), const Locale('en')]) {
            tester.view.physicalSize = Size(width, 700);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(
              buildTestApp(
                child: FlightResultsPage(search: search),
                size: Size(width, 700),
                locale: locale,
              ),
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });
}
