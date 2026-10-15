part of 'travel_search_card.dart';

class _TravelField extends StatelessWidget {
  const _TravelField({
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          border: Border.all(
            color: isDark
                ? AppColors.orange.withValues(alpha: .22)
                : Theme.of(context).dividerColor.withValues(alpha: .35),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    size: 17,
                    color: isDark ? AppColors.orangeLight : AppColors.muted,
                  ),
              ],
            ),
            if (caption != null)
              Text(
                caption!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}
