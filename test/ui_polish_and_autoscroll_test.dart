import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/theme/app_theme.dart';
import 'package:safer_be_project/features/home/presentation/widgets/home_website_sections.dart';
import 'package:safer_be_project/features/search/presentation/widgets/ai_travel_search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestScope({
  required Widget child,
  Locale locale = const Locale('ar'),
  double width = 360,
  double height = 800,
}) {
  final controller = AppController();
  return AppControllerScope(
    notifier: controller,
    child: MaterialApp(
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
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UI Polish & Auto-scrolling Carousel Tests', () {
    testWidgets('AiTravelSearchBar does not embed cramped logo inside text field', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        createTestScope(
          child: AiTravelSearchBar(
            controller: controller,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No Image.asset with brand logo inside the search bar
      expect(find.byType(Image), findsNothing);

      // Search icon is present in leading badge
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Typing text shows clear button
      controller.text = 'Dubai';
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tapping clear button clears text
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('PopularRoutesSection auto-scrolls smoothly over 2-second intervals', (tester) async {
      await tester.pumpWidget(
        createTestScope(
          child: const SingleChildScrollView(
            child: PopularRoutesSection(autoScroll: true),
          ),
        ),
      );
      await tester.pump();

      final scrollableFinder = find.byType(Scrollable).last;
      final initialOffset = tester.state<ScrollableState>(scrollableFinder).position.pixels;
      expect(initialOffset, 0.0);

      // Advance by 2 seconds
      await tester.pump(const Duration(seconds: 2));
      // Pump animation duration
      await tester.pump(const Duration(milliseconds: 600));

      final advancedOffset = tester.state<ScrollableState>(scrollableFinder).position.pixels;
      expect(advancedOffset, greaterThan(0.0));
    });

    testWidgets('TopDestinationHotelsSection initializes and renders properly', (tester) async {
      await tester.pumpWidget(
        createTestScope(
          child: const SingleChildScrollView(
            child: TopDestinationHotelsSection(autoScroll: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TopDestinationHotelsSection), findsOneWidget);
    });
  });
}
