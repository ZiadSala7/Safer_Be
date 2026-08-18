import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/theme/app_theme.dart';
import 'package:safer_be_project/features/home/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Iterable<TextStyle> textStyles(TextTheme theme) => <TextStyle?>[
  theme.displayLarge,
  theme.displayMedium,
  theme.displaySmall,
  theme.headlineLarge,
  theme.headlineMedium,
  theme.headlineSmall,
  theme.titleLarge,
  theme.titleMedium,
  theme.titleSmall,
  theme.bodyLarge,
  theme.bodyMedium,
  theme.bodySmall,
  theme.labelLarge,
  theme.labelMedium,
  theme.labelSmall,
].whereType<TextStyle>();

Widget testApp({required Size size, Locale locale = const Locale('ar')}) {
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
        home: Scaffold(body: HomePage()),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('app theme applies the locale font to every text style', () {
    for (final localeAndFont in [
      (const Locale('ar'), AppTheme.arabicFontFamily),
      (const Locale('en'), AppTheme.englishFontFamily),
    ]) {
      final (locale, expectedFont) = localeAndFont;
      final theme = AppTheme.light(locale);

      for (final style in [
        ...textStyles(theme.textTheme),
        ...textStyles(theme.primaryTextTheme),
      ]) {
        expect(style.fontFamily, expectedFont);
      }
      expect(
        theme.navigationBarTheme.labelTextStyle?.resolve({})?.fontFamily,
        expectedFont,
      );
    }
  });

  testWidgets('home renders in Arabic on a narrow phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(size: const Size(320, 720)));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsNothing);
    expect(find.text('طيران'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home can render in English', (tester) async {
    await tester.pumpWidget(
      testApp(size: const Size(390, 844), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flights'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
