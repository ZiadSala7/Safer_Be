part of 'home_page.dart';

class _TrustStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Row(
      children: [
        _TrustItem(
          icon: Icons.support_agent_rounded,
          label: context.tr('support'),
          onTap: () => SaferBeSupportChatSheet.show(context),
        ),
        const SizedBox(width: 7),
        _TrustItem(
          icon: Icons.verified_user_outlined,
          label: context.tr('secure'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.isArabic
                    ? 'جميع المعاملات والمدفوعات مشفرة ومحمية بأعلى معايير الأمان 🔒'
                    : 'All transactions & payments are encrypted & bank-grade secured 🔒',
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        _TrustItem(
          icon: Icons.stars_rounded,
          label: context.tr('loyalty'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.isArabic
                    ? 'برنامج ولاء نادي سافر بي (جوك VIP) يمنحك نقاطاً مجانية مع كل حجز ⭐'
                    : 'Safer Be Club loyalty program earns you instant rewards with every booking ⭐',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.teal, size: 21),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}

