import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/forgot_password_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../notifications/presentation/widgets/notifications_settings_card.dart';
import '../../data/repositories/api_profile_repository.dart';
import 'about_us_page.dart';
import 'branches_page.dart';
import 'contact_us_page.dart';
import 'faq_page.dart';
import 'wallet_page.dart';

part 'profile_header_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppControllerScope.of(context);
    final user = app.user;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          // Screen Title
          Text(
            context.tr('myAccount'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),

          // User Header Card
          _ProfileHeaderCard(
            name: app.isGuest ? null : user?.name,
            email: app.isGuest ? null : user?.email,
          ),
          const SizedBox(height: 16),

          // Guest Banner (Sign in / Create Account)
          if (app.isGuest) ...[
            _GuestActions(),
            const SizedBox(height: 16),
          ],

          // SECTION 1: محفظتي (My Wallet)
          _SectionTitle(title: context.tr('myWallet')),
          const SizedBox(height: 8),

          // Main Wallet Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.account_balance_wallet_rounded,
              title: context.tr('wallet'),
              value: '0.00 SAR',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletPage()),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Side-by-side action cards: Add points & Redeem voucher
          Row(
            children: [
              Expanded(
                child: _QuickWalletCard(
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: AppColors.teal,
                  title: context.tr('addPointsToWallet'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletPage(initialAction: 'addPoints'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickWalletCard(
                  icon: Icons.card_giftcard_rounded,
                  iconColor: AppColors.orange,
                  title: context.tr('redeemVoucher'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletPage(initialAction: 'redeemVoucher'),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // SECTION 2: المعلومات الشخصية (Personal Information)
          _SectionTitle(title: context.tr('personalInfo')),
          const SizedBox(height: 8),

          if (app.isGuest)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: EdgeInsets.zero,
              child: _SettingsTile(
                icon: Icons.manage_accounts_outlined,
                title: context.tr('accountSettings'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),
            )
          else
            _LoggedInActions(),

          const SizedBox(height: 22),

          // SECTION 3: إعدادات التطبيق (App Settings)
          _SectionTitle(title: context.tr('appSettings')),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: context.tr('language'),
                  value: isAr ? 'العربية' : 'English',
                  onTap: app.toggleLocale,
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),
                _SettingsTile(
                  icon: app.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : (app.themeMode == ThemeMode.system
                          ? Icons.brightness_auto_rounded
                          : Icons.light_mode_outlined),
                  title: context.tr('theme'),
                  value: context.tr(
                    app.themeMode == ThemeMode.dark
                        ? 'darkMode'
                        : (app.themeMode == ThemeMode.system
                            ? 'systemMode'
                            : 'lightMode'),
                  ),
                  onTap: () => _showThemeDialog(context),
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: context.tr('notifications'),
                  onTap: () => _showNotificationsBottomSheet(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // SECTION 4: معلومات مهمة (Important Information)
          _SectionTitle(title: context.tr('importantInfo')),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.headset_mic_rounded,
                  title: context.tr('contactUs'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactUsPage()),
                  ),
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),
                _SettingsTile(
                  icon: Icons.location_on_outlined,
                  title: context.tr('storeLocations'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BranchesPage()),
                  ),
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: context.tr('assistance'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaqPage()),
                  ),
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: context.tr('aboutUs'),
                  value: '(v1.2.2)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsPage()),
                  ),
                ),
              ],
            ),
          ),

          // Logged in Sign Out Button
          if (!app.isGuest) ...[
            const SizedBox(height: 22),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: EdgeInsets.zero,
              child: _SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: Theme.of(context).colorScheme.error,
                title: context.tr('signOut'),
                titleColor: Theme.of(context).colorScheme.error,
                onTap: () async {
                  await app.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('signedOutMessage'))),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.teal),
                const SizedBox(width: 8),
                Text(
                  context.tr('notifications'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const NotificationsSettingsCard(),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final app = AppControllerScope.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.palette_outlined, color: AppColors.teal),
            const SizedBox(width: 10),
            Text(context.tr('chooseTheme')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.light_mode_rounded, color: AppColors.orange),
              title: Text(
                context.tr('lightMode'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: app.themeMode == ThemeMode.light
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
                  : null,
              onTap: () {
                app.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.dark_mode_rounded, color: AppColors.orange),
              title: Text(
                context.tr('darkMode'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: app.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.orange)
                  : null,
              onTap: () {
                app.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.brightness_auto_rounded, color: AppColors.teal),
              title: Text(
                context.tr('systemMode'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: app.themeMode == ThemeMode.system
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
                  : null,
              onTap: () {
                app.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuickWalletCard extends StatelessWidget {
  const _QuickWalletCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: AppColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('guestBody'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('guestHint'),
                      style: const TextStyle(
                        fontSize: 11.5,
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
            icon: const Icon(Icons.login_rounded, size: 18),
            label: Text(context.tr('signIn')),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    decoration: InputDecoration(
                      labelText: context.tr('otpCode'),
                      hintText: '123456',
                    ),
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
                                      : context.tr('verificationFailed'),
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: context.tr('editProfile'),
            onTap: () => _showEditProfileDialog(context, app),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16),
          _SettingsTile(
            icon: Icons.verified_user_outlined,
            title: context.tr('verifyPhone'),
            onTap: () => _showPhoneOtpDialog(context, app),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16),
          _SettingsTile(
            icon: Icons.lock_reset_rounded,
            title: context.tr('forgotPassword'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
            ),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: const Color(0xFFDC2626),
            title: context.tr('deleteAccount'),
            titleColor: const Color(0xFFDC2626),
            onTap: () => _showDeleteAccountDialog(context, app),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? value;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? (isDark ? AppColors.orangeLight : AppColors.teal);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
