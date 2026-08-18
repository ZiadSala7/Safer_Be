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
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appController = AppController();
    addTearDown(appController.dispose);

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
          home: OnboardingPage(repository: FakeOnboardingRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('العالم أقرب مما تتخيل'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('كل رحلتك في مكان واحد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
