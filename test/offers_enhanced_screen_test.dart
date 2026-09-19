import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/network/api_client.dart';
import 'package:safer_be_project/core/theme/app_theme.dart';
import 'package:safer_be_project/features/offers/data/repositories/api_offers_repository.dart';
import 'package:safer_be_project/features/offers/data/repositories/local_offers_repository.dart';
import 'package:safer_be_project/features/offers/presentation/pages/offers_page.dart';
import 'package:safer_be_project/features/offers/presentation/widgets/offer_booking_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildTestOffersPage({
  required ApiOffersRepository repository,
  Locale locale = const Locale('ar'),
  Size size = const Size(360, 800),
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
        home: Scaffold(body: OffersPage(repository: repository)),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final sampleApiPayload = {
    'success': true,
    'data': [
      {
        'id': 101,
        'title': 'خصم خاص على رحلات دبي',
        'description': 'وفر 15% على جميع رحلات الطيران إلى دبي',
        'code': 'FLYDXB15',
        'discount_type': 'percentage',
        'discount_value': 15,
        'category': 'flights',
        'min_booking_amount': 500,
        'max_discount': 200,
        'valid_until': '2026-12-31T23:59:59Z',
      },
      {
        'id': 102,
        'title': 'إقامة فاخرة في القاهرة',
        'description': 'خصم بقيمة 100 ر.س على حجز الفنادق في القاهرة',
        'code': 'CAIRO100',
        'discount_type': 'fixed',
        'discount_value': 100,
        'currency': 'SAR',
        'category': 'hotels',
        'valid_until': '2026-11-30T23:59:59Z',
      },
    ],
  };

  group('Enhanced Offers Screen & Pure API Data Verification', () {
    test('LocalOffersRepository contains zero unlinked mock offers', () async {
      final localRepo = LocalOffersRepository();
      expect(localRepo.getAll(), isEmpty);
      expect(await localRepo.getAvailableOffers(), isEmpty);
    });

    testWidgets('OffersPage renders hero banner and verified live badge', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(sampleApiPayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = ApiOffersRepository(client: ApiClient(client: mockClient));

      await tester.pumpWidget(
        buildTestOffersPage(repository: repo, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // Verified badge and sync text
      expect(find.text('عروض حصرية موثقة'), findsOneWidget);
      expect(find.text('متصل بالنظام المباشر'), findsOneWidget);
      expect(find.text('وفر أكثر على رحلاتك القادمة'), findsOneWidget);

      // Offer cards from API
      expect(find.text('خصم خاص على رحلات دبي'), findsOneWidget);
      expect(find.text('FLYDXB15'), findsOneWidget);
      expect(find.text('إقامة فاخرة في القاهرة'), findsOneWidget);
      expect(find.text('CAIRO100'), findsOneWidget);

      // Zero mock offers
      expect(find.text('ALULA15'), findsNothing);
      expect(find.text('JEDDAH20'), findsNothing);
      expect(find.text('TRANSFER25'), findsNothing);
    });

    testWidgets('Filter chips filter items and display category counts correctly', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(sampleApiPayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = ApiOffersRepository(client: ApiClient(client: mockClient));

      await tester.pumpWidget(
        buildTestOffersPage(repository: repo, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // Flights chip with count: طيران (1)
      expect(find.text('طيران (1)'), findsOneWidget);
      // Hotels chip with count: فنادق (1)
      expect(find.text('فنادق (1)'), findsOneWidget);

      // Tap on Flights filter chip
      await tester.tap(find.text('طيران (1)'));
      await tester.pumpAndSettle();

      expect(find.text('خصم خاص على رحلات دبي'), findsOneWidget);
      expect(find.text('إقامة فاخرة في القاهرة'), findsNothing);

      // Tap on Hotels filter chip
      await tester.tap(find.text('فنادق (1)'));
      await tester.pumpAndSettle();

      expect(find.text('خصم خاص على رحلات دبي'), findsNothing);
      expect(find.text('إقامة فاخرة في القاهرة'), findsOneWidget);

      // Tap on Transfers (empty category for this payload)
      await tester.tap(find.text('تنقلات'));
      await tester.pumpAndSettle();

      // Empty state for category
      expect(find.text('لا توجد عروض لهذه الفئة'), findsOneWidget);
      expect(find.text('عرض جميع العروض'), findsOneWidget);

      // Tap view all offers button restores all
      await tester.tap(find.text('عرض جميع العروض'));
      await tester.pumpAndSettle();

      expect(find.text('خصم خاص على رحلات دبي'), findsOneWidget);
      expect(find.text('إقامة فاخرة في القاهرة'), findsOneWidget);
    });

    testWidgets('Empty API state renders empty graphic with refresh button', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = ApiOffersRepository(client: ApiClient(client: mockClient));

      await tester.pumpWidget(
        buildTestOffersPage(repository: repo, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد عروض متاحة حالياً'), findsOneWidget);
      expect(find.text('تحديث العروض'), findsOneWidget);
    });

    testWidgets(
      'OffersPage renders on narrow 320px screen in Arabic (RTL) without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode(sampleApiPayload),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final repo = ApiOffersRepository(client: ApiClient(client: mockClient));

        await tester.pumpWidget(
          buildTestOffersPage(
            repository: repo,
            locale: const Locale('ar'),
            size: const Size(320, 700),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('خصم خاص على رحلات دبي'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'OffersPage renders on narrow 320px screen in English (LTR) without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 201,
                  'title': 'Dubai Super Flight Special',
                  'description': 'Enjoy 15% off all flights to DXB with Emirates',
                  'code': 'EMIRATES15',
                  'discount_type': 'percentage',
                  'discount_value': 15,
                  'category': 'flights',
                  'valid_until': '2026-12-31T23:59:59Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final repo = ApiOffersRepository(client: ApiClient(client: mockClient));

        await tester.pumpWidget(
          buildTestOffersPage(
            repository: repo,
            locale: const Locale('en'),
            size: const Size(320, 700),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dubai Super Flight Special'), findsOneWidget);
        expect(find.text('Verified Live Deals'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Tapping Book with Offer opens booking sheet', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(sampleApiPayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = ApiOffersRepository(client: ApiClient(client: mockClient));

      await tester.pumpWidget(
        buildTestOffersPage(repository: repo, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // Tap first "احجز بهذا العرض" button
      await tester.tap(find.text('احجز بهذا العرض').first);
      await tester.pumpAndSettle();

      // OfferBookingSheet is displayed
      expect(find.byType(OfferBookingSheet), findsOneWidget);
    });
  });
}
