part of 'trips_page.dart';

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.onExplore, this.onFindBooking});

  final VoidCallback onExplore;
  final VoidCallback? onFindBooking;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.navySoft,
                    AppColors.teal.withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      AppAssets.brandSymbol,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.luggage_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('noTrips'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('noTripsBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.6, fontSize: 13),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (onFindBooking != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onFindBooking,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(context.tr('findBooking')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onExplore,
                    icon: const Icon(Icons.explore_rounded, size: 18),
                    label: Text(context.tr('explore')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
