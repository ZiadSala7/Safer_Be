import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/auth_page_shell.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController();
  bool loading = false;
  bool sent = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!email.text.trim().contains('@')) {
      setState(() => error = context.tr('validEmail'));
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = AppControllerScope.of(context).authRepository;
      await repo.forgotPassword(email.text.trim());
      if (!mounted) return;
      setState(() => sent = true);
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageShell(
    title: context.tr('forgotPassword'),
    headline: context.tr('forgotPasswordHeadline'),
    body: context.tr('forgotPasswordBody'),
    icon: Icons.lock_reset_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sent) ...[
          AuthNotice(
            icon: Icons.mark_email_read_outlined,
            title: context.tr('resetEmailSent'),
            body: context.tr('resetEmailSentBody'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.login_rounded),
              label: Text(
                context.tr('backToLogin'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ] else ...[
          AppTextField(
            label: context.tr('email'),
            controller: email,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
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
                  : const Icon(Icons.send_rounded),
              label: Text(
                loading ? context.tr('sendingRequest') : context.tr('sendResetLink'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('backToLogin')),
          ),
        ],
      ],
    ),
  );
}
