part of 'trips_page.dart';

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFE8FBFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 42,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('noTrips'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              context.tr('noTripsBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.6),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onExplore,
              child: Text(context.tr('explore')),
            ),
          ],
        ),
      ),
    ),
  );
}
