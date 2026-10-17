part of 'home_page.dart';

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.action,
    required this.height,
    required this.children,
    this.onAction,
  });

  final String title;
  final String action;
  final double height;
  final List<Widget> children;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
    child: Column(
      children: [
        SectionHeader(title: title, action: action, onAction: onAction ?? () {}),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(width: 11),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    ),
  );
}

class _OffersShimmerSection extends StatelessWidget {
  const _OffersShimmerSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        children: [
          SectionHeader(
            title: context.tr('exclusive'),
            action: context.tr('seeAll'),
            onAction: () {},
          ),
          SizedBox(
            height: 145,
            child: ShimmerEffect(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 11),
                itemBuilder: (_, _) => Container(
                  width: 210,
                  height: 145,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.navySoft : Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: isDark
                          ? AppColors.orange.withValues(alpha: 0.12)
                          : AppColors.teal.withValues(alpha: 0.12),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          ShimmerBox(width: 60, height: 22, borderRadius: 6),
                          ShimmerBox(width: 44, height: 18, borderRadius: 4),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(width: 140, height: 16, borderRadius: 5),
                          SizedBox(height: 6),
                          ShimmerBox(width: 90, height: 12, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
