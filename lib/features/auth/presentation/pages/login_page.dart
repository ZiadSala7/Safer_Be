import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/auth_page_shell.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;
  bool _isVerifyEmailError = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  bool get _hasValidEmail => email.text.trim().contains('@');

  Future<void> submit() async {
    if (!_hasValidEmail || password.text.length < 8) {
      setState(() => error = context.tr('validLogin'));
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    final app = AppControllerScope.of(context);
    try {
      final user = await app.authRepository.login(
        email.text.trim(),
        password.text,
      );
      if (!mounted) return;
      app.signedIn(user);
      Navigator.of(context).pop();
    } catch (exception) {
      if (mounted) {
        final msg = exception.toString();
        final isVerify = msg.toLowerCase().contains('verify your email');
        setState(() {
          error = msg;
          _isVerifyEmailError = isVerify;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageShell(
    title: context.tr('signIn'),
    headline: context.tr('welcomeBack'),
    body: context.tr('signInBody'),
    icon: Icons.flight_takeoff_rounded,
    footer: const SizedBox.shrink(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthBenefitStrip(
          items: [
            AuthBenefitItem(
              icon: Icons.confirmation_number_outlined,
              label: context.tr('savedTrips'),
            ),
            AuthBenefitItem(
              icon: Icons.shield_outlined,
              label: context.tr('secureAccount'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: context.tr('email'),
          controller: email,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        AppPasswordField(label: context.tr('password'), controller: password),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
            ),
            child: Text(context.tr('forgotPassword')),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          AuthNotice(
            icon: _isVerifyEmailError
                ? Icons.mark_email_unread_rounded
                : Icons.error_outline_rounded,
            title: _isVerifyEmailError
                ? context.tr('emailSentTitle')
                : context.tr('signIn'),
            body: _isVerifyEmailError
                ? context.tr('emailVerifyHint')
                : error!,
            isError: !_isVerifyEmailError,
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: loading ? null : submit,
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(
              loading ? context.tr('sendingRequest') : context.tr('signIn'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(context.tr('continueAsGuest')),
        ),
        const Divider(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                context.tr('newHere'),
                style: const TextStyle(color: AppColors.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(context.tr('createAccount')),
            ),
          ],
        ),
      ],
    ),
  );
}
