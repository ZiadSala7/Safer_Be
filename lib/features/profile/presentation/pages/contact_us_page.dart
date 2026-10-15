import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../support/presentation/pages/safer_be_support_chat_sheet.dart';
import 'faq_page.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  static const String phone = '920011244';
  static const String email = 'support@saferbe.com';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('contactUs'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Banner: Looking for a quick answer?
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.navySoft : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.teal.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('lookingForQuickAnswer'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('checkCommonHelpTopics'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaqPage()),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    context.tr('frequentlyAskedQuestions'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Contact Methods Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                // WhatsApp
                _ContactListTile(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF16A34A),
                  iconBg: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  title: context.tr('whatsApp'),
                  subtitle: context.tr('contactUsViaWhatsApp'),
                  onTap: () => AppWhatsAppHelper.launchWhatsApp(),
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),

                // Call Us
                _ContactListTile(
                  icon: Icons.phone_in_talk_rounded,
                  iconColor: AppColors.teal,
                  iconBg: AppColors.teal.withValues(alpha: 0.12),
                  title: context.tr('callUs'),
                  subtitle: context.tr('supportTeamAvailable247'),
                  onTap: () async {
                    final uri = Uri.parse('tel:$phone');
                    await launchUrl(uri);
                  },
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),

                // Live Chat
                _ContactListTile(
                  icon: Icons.support_agent_rounded,
                  iconColor: AppColors.orange,
                  iconBg: AppColors.orange.withValues(alpha: 0.12),
                  title: context.tr('liveChat'),
                  subtitle: context.tr('chatWithCustomerService'),
                  onTap: () => SaferBeSupportChatSheet.show(context),
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),

                // Email
                _ContactListTile(
                  icon: Icons.alternate_email_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBg: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  title: context.tr('email'),
                  subtitle: email,
                  onTap: () async {
                    final uri = Uri.parse('mailto:$email');
                    await launchUrl(uri);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Follow Us Section
          Center(
            child: Text(
              context.tr('followUs'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIcon(
                icon: Icons.business_center_rounded,
                tooltip: 'LinkedIn',
                color: const Color(0xFF0A66C2),
                url: 'https://www.linkedin.com/company/saferbe',
              ),
              const SizedBox(width: 14),
              _SocialIcon(
                icon: Icons.camera_alt_rounded,
                tooltip: 'Instagram',
                color: const Color(0xFFE4405F),
                url: 'https://www.instagram.com/saferbe',
              ),
              const SizedBox(width: 14),
              _SocialIcon(
                icon: Icons.close_rounded,
                tooltip: 'X (Twitter)',
                color: isDark ? Colors.white : Colors.black87,
                url: 'https://x.com/saferbe',
              ),
              const SizedBox(width: 14),
              _SocialIcon(
                icon: Icons.facebook_rounded,
                tooltip: 'Facebook',
                color: const Color(0xFF1877F2),
                url: 'https://www.facebook.com/saferbe',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactListTile extends StatelessWidget {
  const _ContactListTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.url,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final String url;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () async {
          final uri = Uri.tryParse(url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.navySoft : Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
