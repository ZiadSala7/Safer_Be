import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/presentation/pages/hotel_booking_status_page.dart';
import '../../data/repositories/api_trips_repository.dart';
import 'flight_booking_details_page.dart';

class FindBookingSheet extends StatefulWidget {
  const FindBookingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const FindBookingSheet(),
    );
  }

  @override
  State<FindBookingSheet> createState() => _FindBookingSheetState();
}

class _FindBookingSheetState extends State<FindBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _emailController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _repository = ApiTripsRepository();

  int _selectedType = 0; // 0 = Flight, 1 = Hotel
  bool _searching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _referenceController.dispose();
    _emailController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _searching = true;
      _errorMessage = null;
    });

    final reference = _referenceController.text.trim();
    final email = _emailController.text.trim();
    final lastName = _lastNameController.text.trim();

    try {
      if (_selectedType == 0) {
        // Flight guest challenge
        await _repository.getFlightBookingDetails(
          reference,
          guestEmail: email,
          guestLastName: lastName,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FlightBookingDetailsPage(
              bookingReference: reference,
              guestEmail: email,
              guestLastName: lastName,
            ),
          ),
        );
      } else {
        // Hotel guest challenge
        await _repository.getHotelBookingDetails(
          reference,
          guestEmail: email,
          guestLastName: lastName,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => HotelBookingStatusPage(
              bookingReference: reference,
              guestEmail: email,
              guestLastName: lastName,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().contains('404') || e.toString().contains('401')
            ? context.tr('bookingNotFound')
            : '$e';
      });
    } finally {
      if (mounted) setState(() => _searching = false);
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFE8FBFF),
                  child: Icon(Icons.search_rounded, color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('findBooking'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('findBookingDesc'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.flight_rounded, size: 18),
                  label: Text(context.tr('flightBooking')),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.hotel_rounded, size: 18),
                  label: Text(context.tr('hotelBooking')),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (val) => setState(() => _selectedType = val.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: context.tr('bookingReference'),
                hintText: _selectedType == 0 ? 'FLT-... or PNR' : 'BK-... or Juniper code',
                prefixIcon: const Icon(Icons.tag_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('required') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.tr('email'),
                hintText: 'traveler@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return context.tr('required');
                if (!v.contains('@')) return context.tr('validEmail');
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: context.tr('lastName'),
                hintText: 'Smith',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('required') : null,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _searching ? null : _handleSearch,
              icon: _searching
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                context.tr('lookupBooking'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
