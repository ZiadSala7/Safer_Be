part of 'home_page.dart';

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  static void _showSecurityModal(BuildContext context) {
    final isAr = context.l10n.isArabic;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.navySoft
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'أمان مصرفي وحماية 100%' : '100% Bank-Grade Security',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'تشفير 256-bit بمعايير PCI-DSS العالمية'
                            : '256-bit encryption & PCI-DSS global standards',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isAr
                  ? 'جميع المعاملات والمدفوعات وبياناتك مشفرة ومحمية بأعلى معايير الأمان المصرفية العالمية، ولا يتم حفظ أي بيانات حساسة على خوادمنا.'
                  : 'All transactions, payments, and personal data are encrypted with the highest global banking security standards. No sensitive payment data is stored on our servers.',
              style: const TextStyle(fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isAr ? 'حسناً، فهمت' : 'Got it',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showLoyaltyModal(BuildContext context) {
    final isAr = context.l10n.isArabic;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.navySoft
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: AppColors.orange,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'نادي ولاء سافر بي (جوك VIP)' : 'Safer Be VIP Club Loyalty',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'اكسب نقاطاً واستبدلها بخصومات فورية'
                            : 'Earn instant points & redeem for discounts',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isAr
                  ? 'مع كل حجز طيران أو فندق عبر تطبيق سافر بي، تكسب نقاط ولاء فورية تُضاف إلى محفظتك ويمكنك استبدالها بخصومات حصرية على رحلاتك القادمة.'
                  : 'With every flight or hotel booking through the Safer Be app, you earn instant loyalty points added to your wallet that can be redeemed for exclusive discounts.',
              style: const TextStyle(fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isAr ? 'ابدأ الجمع الآن' : 'Start Earning Now',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.l10n.isArabic;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _TrustItem(
            icon: Icons.support_agent_rounded,
            gradientColors: const [Color(0xFF0284C7), Color(0xFF0EA5E9)],
            label: context.tr('support'),
            tag: '24/7',
            subtitle: isAr ? 'دعم متواصل' : 'Always Active',
            onTap: () => SaferBeSupportChatSheet.show(context),
          ),
          const SizedBox(width: 8),
          _TrustItem(
            icon: Icons.verified_user_rounded,
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            label: context.tr('secure'),
            tag: '100%',
            subtitle: isAr ? 'تشفير مصرفي' : 'Bank Grade',
            onTap: () => _showSecurityModal(context),
          ),
          const SizedBox(width: 8),
          _TrustItem(
            icon: Icons.stars_rounded,
            gradientColors: const [Color(0xFFFD7803), Color(0xFFFFB23F)],
            label: context.tr('loyalty'),
            tag: 'VIP',
            subtitle: isAr ? 'نقاط ومكافآت' : 'Earn Rewards',
            onTap: () => _showLoyaltyModal(context),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.gradientColors,
    required this.label,
    required this.tag,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final List<Color> gradientColors;
  final String label;
  final String tag;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: AnimatedPress(
        scaleDown: 0.96,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.orange.withValues(alpha: 0.20)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.orange.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors.first.withValues(alpha: 0.28),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 19),
                      ),
                      Positioned(
                        top: -2,
                        right: -3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.orange : AppColors.navy,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 0.8),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

