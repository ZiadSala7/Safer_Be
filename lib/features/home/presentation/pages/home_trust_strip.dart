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
        ),
        const SizedBox(width: 7),
        _TrustItem(
          icon: Icons.verified_user_outlined,
          label: context.tr('secure'),
        ),
        const SizedBox(width: 7),
        _TrustItem(icon: Icons.stars_rounded, label: context.tr('loyalty')),
      ],
    ),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
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
  );
}
