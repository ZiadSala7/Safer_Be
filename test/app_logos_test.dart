import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/constants/app_assets.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/theme/app_theme.dart';
import 'package:safer_be_project/core/widgets/brand_logo.dart';
import 'package:safer_be_project/features/home/presentation/widgets/home_hero.dart';
import 'package:safer_be_project/features/splash/presentation/widgets/animated_wordmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapWithScope({
  required Widget child,
  Locale locale = const Locale('en'),
  bool isDark = false,
}) {
  final controller = AppController();
  return AppControllerScope(
    notifier: controller,
    child: MaterialApp(
      key: ValueKey('$isDark-$locale'),
      theme: isDark ? AppTheme.dark(locale) : AppTheme.light(locale),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

bool _matchesAsset(Widget widget, String assetName) {
  if (widget is! Image) return false;
  final provider = widget.image;
  if (provider is AssetImage) {
    return provider.assetName == assetName;
  }
  if (provider is ResizeImage && provider.imageProvider is AssetImage) {
    return (provider.imageProvider as AssetImage).assetName == assetName;
  }
  return false;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SaferBe App Logos & Themes Matrix Tests', () {
    test('1. AppAssets.getLogo resolves official logos exactly as specified', () {
      // Dark Mode & English -> logo-01.png
      expect(
        AppAssets.getLogo(isDark: true, isArabic: false),
        AppAssets.logoDarkEn,
      );
      expect(AppAssets.logoDarkEn, 'assets/images/logo-01.png');

      // Dark Mode & Arabic -> logo-02.png
      expect(
        AppAssets.getLogo(isDark: true, isArabic: true),
        AppAssets.logoDarkAr,
      );
      expect(AppAssets.logoDarkAr, 'assets/images/logo-02.png');

      // Light Mode & English -> logo-03.png
      expect(
        AppAssets.getLogo(isDark: false, isArabic: false),
        AppAssets.logoLightEn,
      );
      expect(AppAssets.logoLightEn, 'assets/images/logo-03.png');

      // Light Mode & Arabic -> logo-04.png
      expect(
        AppAssets.getLogo(isDark: false, isArabic: true),
        AppAssets.logoLightAr,
      );
      expect(AppAssets.logoLightAr, 'assets/images/logo-04.png');

      // Places without background: must return transparent logo (logo-01 / logo-02)
      expect(
        AppAssets.getLogo(
          isDark: false,
          isArabic: false,
          withoutBackground: true,
        ),
        AppAssets.logoDarkEn,
      );
      expect(
        AppAssets.getLogo(
          isDark: false,
          isArabic: true,
          withoutBackground: true,
        ),
        AppAssets.logoDarkAr,
      );
      expect(
        AppAssets.getLogo(
          isDark: true,
          isArabic: false,
          withoutBackground: true,
        ),
        AppAssets.logoDarkEn,
      );
      expect(
        AppAssets.getLogo(
          isDark: true,
          isArabic: true,
          withoutBackground: true,
        ),
        AppAssets.logoDarkAr,
      );
    });

    testWidgets('2. HomeHero appbar uses transparent logo without background in Arabic and English', (
      tester,
    ) async {
      // Test English HomeHero
      await tester.pumpWidget(
        _wrapWithScope(
          locale: const Locale('en'),
          child: const HomeHero(),
        ),
      );
      await tester.pump();

      // Must find logo-01.png (without background)
      expect(
        find.byWidgetPredicate((w) => _matchesAsset(w, AppAssets.logoDarkEn)),
        findsOneWidget,
      );

      // Test Arabic HomeHero
      await tester.pumpWidget(
        _wrapWithScope(
          locale: const Locale('ar'),
          child: const HomeHero(),
        ),
      );
      await tester.pump();

      // Must find logo-02.png (without background)
      expect(
        find.byWidgetPredicate((w) => _matchesAsset(w, AppAssets.logoDarkAr)),
        findsOneWidget,
      );
    });

    testWidgets('3. Splash AnimatedWordmark displays appropriate logo for all 4 combinations', (
      tester,
    ) async {
      final cases = [
        {'dark': true, 'ar': false, 'expected': AppAssets.logoDarkEn},
        {'dark': true, 'ar': true, 'expected': AppAssets.logoDarkAr},
        {'dark': false, 'ar': false, 'expected': AppAssets.logoLightEn},
        {'dark': false, 'ar': true, 'expected': AppAssets.logoLightAr},
      ];

      for (final c in cases) {
        final isDark = c['dark'] as bool;
        final isAr = c['ar'] as bool;
        final expectedAsset = c['expected'] as String;

        await tester.pumpWidget(
          _wrapWithScope(
            isDark: isDark,
            locale: Locale(isAr ? 'ar' : 'en'),
            child: AnimatedWordmark(
              progress: 0.5,
              asset: expectedAsset,
              darkBackground: isDark,
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byWidgetPredicate((w) => _matchesAsset(w, expectedAsset)),
          findsOneWidget,
          reason: 'Expected $expectedAsset for isDark=$isDark, isAr=$isAr',
        );
      }
    });

    testWidgets('4. SaferBeWordmark adapts to dark/light and withoutBackground', (
      tester,
    ) async {
      // In light mode without background -> should use logo-01
      await tester.pumpWidget(
        _wrapWithScope(
          isDark: false,
          locale: const Locale('en'),
          child: const SaferBeWordmark(withoutBackground: true),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => _matchesAsset(w, AppAssets.logoDarkEn)),
        findsOneWidget,
      );

      // In light mode with background -> should use logo-03
      await tester.pumpWidget(
        _wrapWithScope(
          isDark: false,
          locale: const Locale('en'),
          child: const SaferBeWordmark(withoutBackground: false),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => _matchesAsset(w, AppAssets.logoLightEn)),
        findsOneWidget,
      );

      // In dark mode -> should use logo-01
      await tester.pumpWidget(
        _wrapWithScope(
          isDark: true,
          locale: const Locale('en'),
          child: const SaferBeWordmark(withoutBackground: false),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => _matchesAsset(w, AppAssets.logoDarkEn)),
        findsOneWidget,
      );
    });
  });
}
