import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/presentation/pages/hotel_booking_status_page.dart';
import '../../data/repositories/api_trips_repository.dart';
import '../../domain/entities/trip.dart';
import '../../../settings/presentation/pages/admin_settings_sheet.dart';
import 'admin_customer_bookings_sheet.dart';
import 'find_booking_sheet.dart';
import 'flight_booking_details_page.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('trips'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => FindBookingSheet.show(context),
                      icon: const Icon(Icons.search_rounded, color: AppColors.teal),
                      tooltip: context.tr('findBooking'),
                    ),
                    IconButton(
                      onPressed: loading ? null : _loadTrips,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: context.tr('refreshStatus'),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (val) {
                        if (val == 'admin') {
                          AdminCustomerBookingsSheet.show(context);
                        } else if (val == 'settings') {
                          AdminSettingsSheet.show(context);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'admin',
                          child: Row(
                            children: [
                              const Icon(Icons.admin_panel_settings_outlined, size: 18, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('adminCustomerBookings'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              const Icon(Icons.settings_suggest_outlined, size: 18, color: AppColors.teal),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('adminSettings'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                ? _EmptyTrips(
                    onExplore: () {},
                    onFindBooking: () => FindBookingSheet.show(context),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTrips,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return _TripCard(
                          trip: trip,
                          onTap: trip.reference.isNotEmpty
                              ? () async {
                                  if (trip.type == 'hotel') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => HotelBookingStatusPage(
                                          bookingReference: trip.reference,
                                          hotelName: trip.route,
                                          supplier: trip.provider,
                                        ),
                                      ),
                                    );
                                  } else {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => FlightBookingDetailsPage(
                                          bookingReference: trip.reference,
                                          initialTrip: trip,
                                        ),
                                      ),
                                    );
                                  }
                                  _loadTrips();
                                }
                              : null,
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
