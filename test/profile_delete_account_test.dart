import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/theme/app_theme.dart';
import 'package:safer_be_project/features/auth/domain/entities/auth_user.dart';
import 'package:safer_be_project/features/auth/domain/repositories/auth_repository.dart';
import 'package:safer_be_project/features/profile/presentation/pages/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository implements AuthRepository {
  bool deleteAccountCalled = false;
  bool logoutCalled = false;

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<AuthUser> login(String email, String password) async =>
      const AuthUser(name: 'Test User', email: 'test@example.com');

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async => const AuthUser(name: 'Test User', email: 'test@example.com');

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {}

  @override
  Future<AuthUser> me() async =>
      const AuthUser(name: 'Test User', email: 'test@example.com');

  @override
  Future<bool> hasSession() async => true;

  @override
  Future<AuthUser?> readCachedUser() async => null;

  @override
  Future<void> writeCachedUser(AuthUser user) async {}
}

Widget buildProfileTestScope({
  required AppController controller,
  Locale locale = const Locale('ar'),
  double width = 360,
  double height = 800,
}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
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
        home: const Scaffold(body: ProfilePage()),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Profile Screen Delete Account Feature Tests', () {
    testWidgets('Guest state does not show delete account button', (tester) async {
      final fakeAuth = FakeAuthRepository();
      final controller = AppController(authRepository: fakeAuth)..locale = const Locale('ar');

      await tester.pumpWidget(buildProfileTestScope(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('حذف الحساب'), findsNothing);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
    });

    testWidgets('Logged-in state shows delete account button in Arabic without overflow', (tester) async {
      for (final width in [360.0, 320.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        final fakeAuth = FakeAuthRepository();
        final controller = AppController(authRepository: fakeAuth)
          ..locale = const Locale('ar')
          ..signedIn(const AuthUser(name: 'سلطان الشمري', email: 'sultan@example.com'));

        await tester.pumpWidget(
          buildProfileTestScope(controller: controller, width: width, locale: const Locale('ar')),
        );
        await tester.pumpAndSettle();

        expect(find.text('حذف الحساب'), findsOneWidget);
        expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Logged-in state shows delete account button in English without overflow', (tester) async {
      for (final width in [360.0, 320.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        final fakeAuth = FakeAuthRepository();
        final controller = AppController(authRepository: fakeAuth)
          ..locale = const Locale('en')
          ..signedIn(const AuthUser(name: 'John Doe', email: 'john@example.com'));

        await tester.pumpWidget(
          buildProfileTestScope(controller: controller, width: width, locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Delete Account'), findsOneWidget);
        expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Tapping delete account opens confirmation dialog and can cancel', (tester) async {
      final fakeAuth = FakeAuthRepository();
      final controller = AppController(authRepository: fakeAuth)
        ..locale = const Locale('ar')
        ..signedIn(const AuthUser(name: 'سلطان الشمري', email: 'sultan@example.com'));

      await tester.pumpWidget(buildProfileTestScope(controller: controller));
      await tester.pumpAndSettle();

      // Tap Delete Account tile
      await tester.tap(find.text('حذف الحساب'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.text('حذف الحساب نهائياً'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Cancel
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Dialog closed and user still logged in
      expect(find.text('حذف الحساب نهائياً'), findsNothing);
      expect(controller.isGuest, isFalse);
      expect(fakeAuth.deleteAccountCalled, isFalse);
    });

    testWidgets('Confirming delete account invokes deleteAccount and resets to guest', (tester) async {
      final fakeAuth = FakeAuthRepository();
      final controller = AppController(authRepository: fakeAuth)
        ..locale = const Locale('ar')
        ..signedIn(const AuthUser(name: 'سلطان الشمري', email: 'sultan@example.com'));

      await tester.pumpWidget(buildProfileTestScope(controller: controller));
      await tester.pumpAndSettle();

      // Tap Delete Account tile
      await tester.tap(find.text('حذف الحساب'));
      await tester.pumpAndSettle();

      // Confirm Delete inside dialog
      final confirmBtn = find.widgetWithText(FilledButton, 'حذف الحساب');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify backend was called, session cleared, state switched to guest
      expect(fakeAuth.deleteAccountCalled, isTrue);
      expect(controller.isGuest, isTrue);
      expect(controller.user, isNull);

      // SnackBar shown
      expect(find.text('تم حذف حسابك بنجاح'), findsOneWidget);

      // Profile page now renders in guest mode
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('حذف الحساب'), findsNothing);
    });
  });
}
