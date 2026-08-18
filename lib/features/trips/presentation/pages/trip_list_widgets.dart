part of 'trips_page.dart';

class _TripCard extends StatelessWidget {
  const _TripCard({required this.route, required this.details});

  final String route;
  final String details;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE8FBFF),
        child: Icon(Icons.flight_rounded, color: AppColors.teal),
      ),
      title: Text(route, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(details),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
    ),
  );
}
