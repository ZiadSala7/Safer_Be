import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/auth_page_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  String? error;
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  bool get _hasValidEmail => email.text.trim().contains('@');

  Future<void> submit() async {
    final trimmedName = name.text.trim();
    if (trimmedName.isEmpty || !_hasValidEmail) {
      setState(() {
        error = context.tr('validEmail');
      });
      return;
    }
    if (password.text.length < 8) {
      setState(() {
        error = context.tr('passwordMin');
      });
      return;
    }
    if (password.text != confirmPassword.text) {
      setState(() {
        error = context.tr('passwordMismatch');
      });
      return;
    }
    setState(() {
      error = null;
      loading = true;
    });
    final app = AppControllerScope.of(context);
    try {
      await app.authRepository.register(
        name: trimmedName,
        email: email.text.trim(),
        password: password.text,
        passwordConfirmation: confirmPassword.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.teal,
          ),
          title: Text(context.tr('emailSentTitle')),
          content: Text(
            context
                .tr('emailSentBody')
                .replaceAll('{email}', email.text.trim()),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              child: Text(context.tr('goToLogin')),
            ),
          ],
        ),
      );
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.toString();
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageShell(
    title: context.tr('createAccount'),
    headline: context.tr('joinSaferBe'),
    body: context.tr('registerBody'),
    icon: Icons.person_add_alt_1_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthBenefitStrip(
          items: [
            AuthBenefitItem(
              icon: Icons.lock_outline_rounded,
              label: context.tr('secureAccount'),
            ),
            AuthBenefitItem(
              icon: Icons.airplane_ticket_outlined,
              label: context.tr('savedTrips'),
            ),
            AuthBenefitItem(
              icon: Icons.flash_on_outlined,
              label: context.tr('fasterBooking'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: context.tr('fullName'),
          controller: name,
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: context.tr('email'),
          controller: email,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: context.tr('optionalPhone'),
          controller: phone,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        AppPasswordField(label: context.tr('password'), controller: password),
        const SizedBox(height: 14),
        AppPasswordField(
          label: context.tr('confirmPassword'),
          controller: confirmPassword,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          AuthNotice(
            icon: Icons.error_outline_rounded,
            title: context.tr('required'),
            body: error!,
            isError: true,
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
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(
              loading
                  ? context.tr('sendingRequest')
                  : context.tr('createAccount'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('alreadyHaveAccount')),
        ),
      ],
    ),
  );
}
