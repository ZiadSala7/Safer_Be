import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/forgot_password_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../notifications/presentation/widgets/notifications_settings_card.dart';
import '../../../support/presentation/pages/safer_be_support_chat_sheet.dart';
import '../../../../core/widgets/app_store_badges.dart';

import '../../data/repositories/api_profile_repository.dart';

part 'profile_header_card.dart';
part 'profile_settings_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppControllerScope.of(context);
    final user = app.user;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Text(
            context.tr('profile'),
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _ProfileHeaderCard(
            name: app.isGuest ? null : (user?.name),
            email: app.isGuest ? null : (user?.email),
          ),
          const SizedBox(height: 16),
          if (app.isGuest) ...[
            _GuestActions(),
          ] else ...[
            _LoggedInActions(),
          ],
          const SizedBox(height: 18),
          Text(
            context.tr('notifications'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const NotificationsSettingsCard(),
          const SizedBox(height: 18),
          Text(
            context.tr('settings'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _ProfileSettingsCard(
            themeMode: app.themeMode,
            onToggleLocale: app.toggleLocale,
            onToggleTheme: app.toggleTheme,
          ),
        ],
      ),
    );
  }
}

class _GuestActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: AppColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('guestBody'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('guestHint'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            icon: const Icon(Icons.login_rounded),
            label: Text(context.tr('signIn')),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text(context.tr('createAccount')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoggedInActions extends StatelessWidget {
  final _profileRepository = ApiProfileRepository();

  void _showEditProfileDialog(BuildContext context, AppController app) {
    final nameController = TextEditingController(text: app.user?.name ?? '');
    final emailController = TextEditingController(text: app.user?.email ?? '');
    final phoneController = TextEditingController(text: app.user?.phone ?? '');
    var loading = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(context.tr('editProfile')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: context.tr('name')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: context.tr('email')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: context.tr('phone')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        final updated = await _profileRepository.updateProfile(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                        );
                        if (app.user != null) {
                          app.signedIn(app.user!.copyWith(
                            name: updated.name,
                            email: updated.email,
                            phone: updated.phone,
                          ));
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoneOtpDialog(BuildContext context, AppController app) {
    final phoneController = TextEditingController(text: app.user?.phone ?? '');
    final otpController = TextEditingController();
    var codeSent = false;
    var loading = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(context.tr('phoneVerification')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!codeSent) ...[
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: context.tr('phone')),
                  ),
                ] else ...[
                  Text(context.tr('enterOtp')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'OTP Code', hintText: '123456'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        if (!codeSent) {
                          await _profileRepository.sendOtp(phone: phoneController.text.trim());
                          setState(() {
                            codeSent = true;
                            loading = false;
                          });
                        } else {
                          final verified = await _profileRepository.verifyOtp(
                            phone: phoneController.text.trim(),
                            code: otpController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  verified
                                      ? context.tr('phoneVerified')
                                      : 'Verification failed',
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.tr(codeSent ? 'verifyCode' : 'sendCode')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppController app) {
    var loading = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: 40,
          ),
          title: Text(
            context.tr('deleteAccountConfirmTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          content: Text(
            context.tr('deleteAccountConfirmMessage'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, height: 1.45),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            FilledButton.icon(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        await app.deleteAccount();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('deleteAccountSuccess')),
                              backgroundColor: AppColors.teal,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setState(() => loading = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('deleteAccountFailed')),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
              icon: loading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_forever_rounded, size: 18),
              label: Text(context.tr('deleteAccountButton')),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppControllerScope.of(context);
    return Column(
      children: [
        _ActionTile(
          icon: Icons.person_outline_rounded,
          title: context.tr('editProfile'),
          onTap: () => _showEditProfileDialog(context, app),
        ),
        const SizedBox(height: 6),
        _ActionTile(
          icon: Icons.verified_user_outlined,
          title: context.tr('verifyPhone'),
          onTap: () => _showPhoneOtpDialog(context, app),
        ),
        const SizedBox(height: 6),
        _ActionTile(
          icon: Icons.lock_reset_rounded,
          title: context.tr('forgotPassword'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
          ),
        ),
        const SizedBox(height: 6),
        _ActionTile(
          icon: Icons.logout_rounded,
          title: context.tr('signOut'),
          color: Theme.of(context).colorScheme.error,
          onTap: () async {
            await app.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('signedOutMessage'))),
              );
            }
          },
        ),
        const SizedBox(height: 6),
        _ActionTile(
          icon: Icons.delete_forever_rounded,
          title: context.tr('deleteAccount'),
          color: const Color(0xFFDC2626),
          onTap: () => _showDeleteAccountDialog(context, app),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.teal;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tileColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tileColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted.withValues(alpha: .5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
