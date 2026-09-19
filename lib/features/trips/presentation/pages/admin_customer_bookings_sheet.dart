import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/presentation/pages/hotel_booking_status_page.dart';
import '../../data/repositories/api_trips_repository.dart';
import '../../domain/entities/trip.dart';
import 'flight_booking_details_page.dart';

class AdminCustomerBookingsSheet extends StatefulWidget {
  const AdminCustomerBookingsSheet({
    this.initialCustomerId,
    super.key,
  });

  final String? initialCustomerId;

  static Future<void> show(BuildContext context, {String? customerId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AdminCustomerBookingsSheet(initialCustomerId: customerId),
    );
  }

  @override
  State<AdminCustomerBookingsSheet> createState() =>
      _AdminCustomerBookingsSheetState();
}

class _AdminCustomerBookingsSheetState
    extends State<AdminCustomerBookingsSheet> {
  final _customerIdController = TextEditingController();
  final _adminTokenController = TextEditingController();
  final _repository = ApiTripsRepository();

  List<Trip> _bookings = const [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomerId != null && widget.initialCustomerId!.isNotEmpty) {
      _customerIdController.text = widget.initialCustomerId!;
      _fetchCustomerBookings();
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _adminTokenController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomerBookings() async {
    final customerId = _customerIdController.text.trim();
    if (customerId.isEmpty) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final adminToken = _adminTokenController.text.trim().isNotEmpty
        ? _adminTokenController.text.trim()
        : null;

    try {
      final list = await _repository.getCustomerBookings(
        customerId,
        adminToken: adminToken,
      );
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _loading = false;
        if (list.isEmpty) {
          _errorMessage = context.tr('noTrips');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFF0E5FF),
                child: Icon(Icons.admin_panel_settings_rounded, color: Colors.purple, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('adminCustomerBookings'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerIdController,
                  decoration: InputDecoration(
                    labelText: context.tr('customerId'),
                    hintText: 'e.g. 1042',
                    prefixIcon: const Icon(Icons.person_pin_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _loading ? null : _fetchCustomerBookings,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size(60, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search_rounded),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: _errorMessage == context.tr('noTrips') ? AppColors.muted : Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_bookings.isNotEmpty) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _bookings.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final item = _bookings[index];
                  final isHotel = item.type == 'hotel';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isHotel
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFE8FBFF),
                      child: Icon(
                        isHotel ? Icons.hotel_rounded : Icons.flight_rounded,
                        color: isHotel ? AppColors.orange : AppColors.teal,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.route,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('${item.reference} · ${item.date}'),
                    trailing: Text(
                      item.status.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (isHotel) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => HotelBookingStatusPage(
                              bookingReference: item.reference,
                              hotelName: item.route,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => FlightBookingDetailsPage(
                              bookingReference: item.reference,
                              initialTrip: item,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
