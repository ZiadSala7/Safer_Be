import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/theme/app_theme.dart';
import 'package:safer_be_project/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:safer_be_project/features/onboarding/presentation/pages/onboarding_page.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  bool completed = false;

  @override
  Future<void> completeOnboarding() async => completed = true;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;
}

void main() {
  testWidgets('onboarding is responsive and advances through Arabic pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appController = AppController();
    addTearDown(appController.dispose);

    final repository = FakeOnboardingRepository();

    await tester.pumpWidget(
      AppControllerScope(
        notifier: appController,
        child: MaterialApp(
          locale: const Locale('ar'),
          theme: AppTheme.light(const Locale('ar')),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OnboardingPage(repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify First Slide (Inspiration)
    expect(find.text('شغفك بالسفر يستحق أن يلهمك!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Advance to Second Slide (Support)
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('عندك استفسار؟ إجابة فورية في 8 ثوانٍ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Advance to Third Slide (Fast Booking)
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('احجز في 5 دقائق فقط!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Advance to Fourth Slide (Loyalty)
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('برنامج ولاء السفر الأفضل! حيث ولاؤك يكافئك دائماً'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Advance to Fifth Slide (Payments)
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('احجز مع خيارات دفع آمنة ومتنوعة'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Advance to Sixth Slide (Essentials)
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('كل احتياجات سفرك مغطاة بالكامل!'), findsOneWidget);
    expect(find.text('ابدأ رحلتك'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap Finish CTA
    await tester.tap(find.text('ابدأ رحلتك'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.completed, isTrue);
  });

  testWidgets('onboarding renders in English and handles complete flow', (
    tester,
  ) async {
    final appController = AppController();
    addTearDown(appController.dispose);
    final repository = FakeOnboardingRepository();

    await tester.pumpWidget(
      AppControllerScope(
        notifier: appController,
        child: MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.light(const Locale('en')),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OnboardingPage(repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your love for travel deserves to be inspired!'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('Got questions? Get answers in 8 sec'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
