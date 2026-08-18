import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/api_trips_repository.dart';
import '../../domain/entities/trip.dart';

part 'empty_trips.dart';
part 'trip_list_widgets.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});
  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final repository = ApiTripsRepository();
  int segment = 0;
  List<Trip> upcoming = const [];
  List<Trip> past = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => loading = true);
    final up = await repository.upcoming;
    final pa = await repository.past;
    if (mounted) {
      setState(() {
        upcoming = up;
        past = pa;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = segment == 0 ? upcoming : past;
    return SafeArea(
      child: Column(
        children: [
          _PageTitle(title: context.tr('trips')),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(context.tr('upcoming'))),
                ButtonSegment(value: 1, label: Text(context.tr('past'))),
              ],
              selected: {segment},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => segment = value.first),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : trips.isEmpty
                ? _EmptyTrips(onExplore: () {})
                : RefreshIndicator(
                    onRefresh: _loadTrips,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return _TripCard(
                          route: trip.route,
                          details: trip.reference.isNotEmpty
                              ? '${trip.provider} · ${trip.date}\n${context.tr('reference')}: ${trip.reference}'
                              : '${trip.provider} · ${trip.date}',
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
