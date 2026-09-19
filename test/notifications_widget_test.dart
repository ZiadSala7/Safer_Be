import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/features/auth/domain/entities/auth_user.dart';
import 'package:safer_be_project/features/notifications/presentation/widgets/notifications_settings_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestWrapper({
  required AppController controller,
  Locale locale = const Locale('en'),
}) {
  return AppControllerScope(
    notifier: controller,
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        body: SingleChildScrollView(
          child: NotificationsSettingsCard(),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationsSettingsCard Widget Tests', () {
    testWidgets('renders push and marketing switches in English', (tester) async {
      final controller = AppController();
      controller.signedIn(
        const AuthUser(
          name: 'Ahmed',
          email: 'ahmed@example.com',
          pushNotificationConsent: false,
          marketingConsent: true,
        ),
      );

      await tester.pumpWidget(createTestWrapper(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Promotions & Offers'), findsOneWidget);
      expect(find.text('Registered Devices'), findsOneWidget);

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      final pushSwitch = tester.widget<Switch>(switches.at(0));
      expect(pushSwitch.value, isFalse);

      final marketingSwitch = tester.widget<Switch>(switches.at(1));
      expect(marketingSwitch.value, isTrue);
    });

    testWidgets('renders in Arabic without layout issues or overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = AppController();
      controller.signedIn(
        const AuthUser(
          name: 'أحمد',
          email: 'ahmed@example.com',
          pushNotificationConsent: true,
          marketingConsent: false,
        ),
      );

      await tester.pumpWidget(createTestWrapper(controller: controller, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('الإشعارات الفورية'), findsOneWidget);
      expect(find.text('العروض الترويجية والخصومات'), findsOneWidget);
      expect(find.text('الأجهزة المسجلة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disables toggles when user is guest', (tester) async {
      final controller = AppController(); // isGuest = true by default

      await tester.pumpWidget(createTestWrapper(controller: controller));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      final pushSwitch = tester.widget<Switch>(switches.at(0));
      expect(pushSwitch.onChanged, isNull);

      final marketingSwitch = tester.widget<Switch>(switches.at(1));
      expect(marketingSwitch.onChanged, isNull);

      // Registered devices tile is hidden for guests
      expect(find.text('Registered Devices'), findsNothing);
    });
  });
}
