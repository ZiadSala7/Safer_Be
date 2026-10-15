import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/features/home/domain/entities/top_destination_item.dart';
import 'package:safer_be_project/features/home/presentation/widgets/home_website_sections.dart';

Widget buildTestWidget({required Widget child, Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        child: child,
      ),
    ),
  );
}

void main() {
  group('Top Destinations & Popular Routes Parity Tests', () {
    test('TopDestinationItem parses API json and resolves images matching website', () {
      final json = {
        'city_id': 3,
        'city_code': '109198',
        'city_name': 'Amman',
        'country_code': 'JO',
        'country_name': 'Jordan',
        'rank': 1,
        'destination_code': '109198',
      };

      final item = TopDestinationItem.fromJson(json);
      expect(item.cityId, 3);
      expect(item.cityName, 'Amman');
      expect(item.countryCode, 'JO');
      expect(item.destinationCode, '109198');
      expect(item.flagUrl, 'https://flagcdn.com/w80/jo.png');
      expect(item.imageUrl, contains('images.unsplash.com'));
      expect(item.localizedCityName(true), 'عمّان');
      expect(item.localizedCityName(false), 'Amman');
      expect(item.localizedCountryName(true), 'الأردن');
      expect(item.localizedCountryName(false), 'Jordan');
    });

    test('Popular flight routes matches the 8 official website routes', () {
      expect(popularFlightRoutes.length, 8);
      final ids = popularFlightRoutes.map((r) => r.id).toList();
      expect(ids, [
        'ruh-dxb',
        'ruh-jed',
        'jed-ruh',
        'jed-cai',
        'ruh-cai',
        'dxb-ruh',
        'jed-dxb',
        'ruh-auh',
      ]);

      final ruhDxb = popularFlightRoutes.first;
      expect(ruhDxb.fromCode, 'RUH');
      expect(ruhDxb.toCode, 'DXB');
      expect(ruhDxb.fromNameAr, 'الرياض');
      expect(ruhDxb.toNameAr, 'دبي');
      expect(ruhDxb.fromNameEn, 'Riyadh');
      expect(ruhDxb.toNameEn, 'Dubai');
      expect(ruhDxb.image, contains('unsplash.com'));
    });

    testWidgets('TopDestinationHotelsSection displays "Top Destinations" in English', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const TopDestinationHotelsSection(),
          locale: const Locale('en'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Must explicitly be "Top Destinations" and NOT "topDestination"
      expect(find.text('Top Destinations'), findsOneWidget);
      expect(find.text('topDestination'), findsNothing);
    });

    testWidgets('TopDestinationHotelsSection displays Arabic title in Arabic locale', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const TopDestinationHotelsSection(),
          locale: const Locale('ar'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('الوجهات الأكثر طلباً'), findsOneWidget);
    });

    testWidgets('PopularRoutesSection displays in English and Arabic without error', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const PopularRoutesSection(),
          locale: const Locale('en'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Popular Routes'), findsOneWidget);
      expect(find.text('RUH'), findsWidgets);
      expect(find.text('DXB'), findsWidgets);
      expect(find.text('Book Route'), findsWidgets);
    });
  });
}
