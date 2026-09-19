import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/theme/app_theme.dart';
import 'package:safer_be_project/features/home/presentation/widgets/home_website_sections.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_offer.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_offer.dart';
import 'package:safer_be_project/features/search/presentation/widgets/flight_offer_card.dart';
import 'package:safer_be_project/features/search/presentation/widgets/hotel_offer_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestScope({
  required Widget child,
  Locale locale = const Locale('ar'),
  double width = 360,
  double height = 800,
}) {
  return MaterialApp(
    theme: AppTheme.light(locale),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: SizedBox(
        width: width,
        height: height,
        child: Material(child: child),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Website Parity Features & Responsive Zero-Overflow Tests', () {
    testWidgets('PopularRoutesSection renders on 360px and 320px without overflow', (tester) async {
      for (final width in [360.0, 320.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createTestScope(
            width: width,
            child: const SingleChildScrollView(
              child: PopularRoutesSection(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('RUH'), findsWidgets);
        expect(find.text('DXB'), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('WhySaferBeSection renders 4 stats & 4 pillars on 320px without overflow', (tester) async {
      for (final width in [360.0, 320.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createTestScope(
            width: width,
            child: const SingleChildScrollView(
              child: WhySaferBeSection(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('500K+'), findsOneWidget);
        expect(find.text('150+'), findsOneWidget);
        expect(find.text('25+'), findsOneWidget);
        expect(find.text('10+'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('OfficialFooterTrustSection renders contact & payment badges on 320px without overflow', (tester) async {
      for (final width in [360.0, 320.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createTestScope(
            width: width,
            child: const SingleChildScrollView(
              child: OfficialFooterTrustSection(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('9200 11 244'), findsOneWidget);
        expect(find.text('مدى Mada'), findsOneWidget);
        expect(find.text('Apple Pay'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('FlightOfferCard renders on narrow 320px screen with Arabic text without overflow', (tester) async {
      final offer = FlightOffer(
        id: 'FLT-TEST-1',
        airline: 'الخطوط الجوية العربية السعودية - السعودية',
        route: 'RUH → DXB',
        time: '14:30',
        price: 450.50,
        currency: 'SAR',
        departureTime: DateTime(2026, 10, 16, 14, 30),
        arrivalTime: DateTime(2026, 10, 16, 16, 40),
        cabinClass: 'درجة رجال الأعمال الفاخرة',
        baggage: 'حقيبتان مسجلتان بوزن 23 كجم لكل حقيبة',
        refundable: true,
        durationMinutes: 130,
        stops: 0,
        labels: const ['أفضل سعر', 'موصى به'],
      );

      for (final width in [360.0, 320.0]) {
        tester.view.physicalSize = Size(width, 600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createTestScope(
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FlightOfferCard(offer: offer),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('RUH → DXB'), findsOneWidget);
        expect(find.text('450.50 SAR'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('HotelOfferCard renders on narrow 320px screen with long hotel name without overflow', (tester) async {
      const hotel = HotelOffer(
        code: 'HTL-TEST-1',
        name: 'منتجع وفندق الريتز كارلتون الفاخر بالرياض العليا',
        location: 'طريق مكة المكرمة، حي العليا، الرياض، المملكة العربية السعودية',
        price: 1850.75,
        currency: 'SAR',
        rating: 4.9,
        supplier: 'tbo',
        imageUrl: '',
        description: 'وصف الفندق الفاخر بالرياض',
      );

      for (final width in [360.0, 320.0]) {
        tester.view.physicalSize = Size(width, 600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createTestScope(
            width: width,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: HotelOfferCard(offer: hotel),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1850.75 SAR'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
