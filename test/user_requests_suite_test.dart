import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/features/home/presentation/pages/home_page.dart';
import 'package:safer_be_project/features/notifications/data/datasources/notification_store.dart';
import 'package:safer_be_project/features/notifications/domain/entities/notification_payload.dart';
import 'package:safer_be_project/features/notifications/presentation/pages/notifications_page.dart';
import 'package:safer_be_project/features/profile/presentation/pages/profile_page.dart';
import 'package:safer_be_project/features/search/domain/entities/flight_search.dart';
import 'package:safer_be_project/features/settings/domain/entities/app_preferences.dart';
import 'package:safer_be_project/features/settings/domain/repositories/app_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemoryAppPreferencesRepository implements AppPreferencesRepository {
  ThemeMode savedTheme = ThemeMode.light;
  Locale savedLocale = const Locale('ar');
  String savedCurrency = 'SAR';

  @override
  Future<AppPreferences> load() async => AppPreferences(
        themeMode: savedTheme,
        locale: savedLocale,
        currency: savedCurrency,
      );

  @override
  Future<void> saveCurrency(String currency) async => savedCurrency = currency;

  @override
  Future<void> saveLocale(Locale locale) async => savedLocale = locale;

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async =>
      savedTheme = themeMode;
}

Widget wrapWithApp({
  required Widget child,
  AppController? controller,
  Locale locale = const Locale('ar'),
}) {
  final app = controller ?? AppController();
  return AppControllerScope(
    notifier: app,
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Flight Search Cabin Class Mappings', () {
    test('getCabinClassName correctly maps Business (2) and all cabins in Arabic and English', () {
      // 1: Economy
      expect(getCabinClassName(1, true), 'اقتصادية');
      expect(getCabinClassName(1, false), 'Economy');

      // 2: Business
      expect(getCabinClassName(2, true), 'أعمال');
      expect(getCabinClassName(2, false), 'Business');

      // 3: First Class
      expect(getCabinClassName(3, true), 'الأولى');
      expect(getCabinClassName(3, false), 'First Class');

      // 4: Premium Economy
      expect(getCabinClassName(4, true), 'اقتصادية مميزة');
      expect(getCabinClassName(4, false), 'Premium Economy');
    });

    test('resolveFlightCabinName resolves string and integer cabin representations correctly', () {
      expect(resolveFlightCabinName(offerCabin: '2', searchCabinClass: 1, isAr: true), 'أعمال');
      expect(resolveFlightCabinName(offerCabin: 'Business', searchCabinClass: 1, isAr: true), 'أعمال');
      expect(resolveFlightCabinName(offerCabin: 'business', searchCabinClass: 1, isAr: false), 'Business');
      expect(resolveFlightCabinName(offerCabin: '', searchCabinClass: 2, isAr: true), 'أعمال');
      expect(resolveFlightCabinName(offerCabin: 'economy', searchCabinClass: 2, isAr: true), 'اقتصادية');
    });

    test('FlightSearch includes cabinClass in all serialized formats', () {
      final search = FlightSearch(
        origin: 'RUH',
        destination: 'DXB',
        departure: DateTime(2026, 8, 1),
        cabinClass: 2, // Business
      );

      final json = search.toJson();
      expect(json['FlightCabinClass'], 2);
      expect(json['cabinClass'], 2);
      expect(json['cabin_class'], 'Business');

      final queryParams = search.toQueryParameters();
      expect(queryParams['cabin'], '2');
      expect(queryParams['cabinClass'], '2');
      expect(queryParams['cabin_class'], '2');
      expect(queryParams['FlightCabinClass'], '2');
    });
  });

  group('2. Notifications Store and Screen', () {
    test('NotificationStore saves, reads, marks read, and deletes notifications', () async {
      await NotificationStore.clearAll();
      expect(await NotificationStore.getNotifications(), isEmpty);
      expect(NotificationStore.unreadCountNotifier.value, 0);

      final notif1 = StoredNotification(
        id: 'notif-1',
        title: 'Booking Confirmed',
        body: 'Your flight to Dubai is confirmed.',
        type: NotificationPayload.typeBookingConfirmed,
        timestamp: DateTime.now(),
        payload: const NotificationPayload(
          type: NotificationPayload.typeBookingConfirmed,
          bookingReference: 'SAFER-123',
          productType: 'flight',
        ),
      );

      await NotificationStore.saveNotification(notif1);
      var list = await NotificationStore.getNotifications();
      expect(list.length, 1);
      expect(list.first.isRead, false);
      expect(NotificationStore.unreadCountNotifier.value, 1);

      await NotificationStore.markAsRead('notif-1');
      list = await NotificationStore.getNotifications();
      expect(list.first.isRead, true);
      expect(NotificationStore.unreadCountNotifier.value, 0);

      await NotificationStore.deleteNotification('notif-1');
      expect(await NotificationStore.getNotifications(), isEmpty);
    });

    testWidgets('NotificationsPage renders empty state and list items correctly', (tester) async {
      await NotificationStore.clearAll();

      await tester.pumpWidget(
        wrapWithApp(
          child: const NotificationsPage(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد إشعارات حتى الآن'), findsOneWidget);

      // Now add a notification and reload
      await NotificationStore.saveNotification(
        StoredNotification(
          id: 'test-2',
          title: 'تأكيد الحجز',
          body: 'تم تأكيد حجز رحلتك بنجاح',
          type: NotificationPayload.typeBookingConfirmed,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: NotificationsPage(key: UniqueKey()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تأكيد الحجز'), findsOneWidget);
      expect(find.text('تم تأكيد حجز رحلتك بنجاح'), findsOneWidget);
    });
  });

  group('3. Removed Distinctive Saudi Destinations Section', () {
    testWidgets('HomePage does not contain the saudiDestinations section', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          child: const Scaffold(body: HomePage()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('وجهات سعودية مميزة'), findsNothing);
      expect(find.text('Saudi destinations'), findsNothing);
    });
  });

  group('4. User-Chosen Theme (Does not follow mobile system)', () {
    test('AppController defaults to ThemeMode.light and allows explicit user selection', () async {
      final repo = InMemoryAppPreferencesRepository();
      final controller = AppController(preferencesRepository: repo);
      addTearDown(controller.dispose);

      expect(controller.themeMode, ThemeMode.light);

      controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(repo.savedTheme, ThemeMode.dark);

      controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
      expect(repo.savedTheme, ThemeMode.light);
    });

    testWidgets('ProfilePage allows choosing ThemeMode via dialog', (tester) async {
      final repo = InMemoryAppPreferencesRepository();
      final controller = AppController(preferencesRepository: repo);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrapWithApp(
          child: const Scaffold(body: ProfilePage()),
          controller: controller,
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll until theme tile is visible
      final themeTile = find.text('المظهر');
      await tester.scrollUntilVisible(themeTile, 300);
      expect(themeTile, findsOneWidget);

      // Tap to open theme dialog
      await tester.tap(themeTile);
      await tester.pumpAndSettle();

      expect(find.text('اختر المظهر'), findsOneWidget);
      expect(find.text('الوضع الفاتح'), findsWidgets);
      expect(find.text('الوضع الداكن'), findsOneWidget);

      // Choose dark mode
      await tester.tap(find.text('الوضع الداكن'));
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.dark);
      expect(repo.savedTheme, ThemeMode.dark);
    });
  });
}
