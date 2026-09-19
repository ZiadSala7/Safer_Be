part of 'home_page.dart';

class _RecentSearches extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(
      children: [
        SectionHeader(
          title: context.tr('recent'),
          action: context.tr('seeAll'),
          onAction: () {},
        ),
        SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _RecentCard(
                title: 'RUH -> DXB',
                subtitle: '25 Jun - ${context.tr('flights')}',
                icon: Icons.flight_takeoff_rounded,
              ),
              const SizedBox(width: 9),
              _RecentCard(
                title: context.tr('jeddah'),
                subtitle: '3 ${context.tr('nights')} - ${context.tr('hotel')}',
                icon: Icons.hotel_rounded,
              ),
              const SizedBox(width: 9),
              _RecentCard(
                title: 'RUH ${context.tr('airport')}',
                subtitle: context.tr('executivePickup'),
                icon: Icons.directions_car_rounded,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 165,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .25),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.teal),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
