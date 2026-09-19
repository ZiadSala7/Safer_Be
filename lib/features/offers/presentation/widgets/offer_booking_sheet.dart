import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/entities/travel_content.dart';
import '../../../search/domain/entities/airport.dart';
import '../../../search/domain/entities/flight_search.dart';
import '../../../search/domain/entities/hotel_search.dart';
import '../../../search/domain/entities/travel_city.dart';
import '../../../search/presentation/pages/airport_picker_page.dart';
import '../../../search/presentation/pages/city_picker_page.dart';
import '../../../search/presentation/pages/flight_results_page.dart';
import '../../../search/presentation/pages/hotel_results_page.dart';
import '../../domain/utils/offer_destination_resolver.dart';

/// Modal bottom sheet that pre-fills the offer's destination (e.g., Cairo Hotel or Dubai flight)
/// and allows the user to interactively choose dates, passengers, and search with the offer.
class OfferBookingSheet extends StatefulWidget {
  const OfferBookingSheet({
    required this.offer,
    super.key,
  });

  final TravelOffer offer;

  static Future<void> show(
    BuildContext context, {
    required TravelOffer offer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OfferBookingSheet(offer: offer),
    );
  }

  @override
  State<OfferBookingSheet> createState() => _OfferBookingSheetState();
}

class _OfferBookingSheetState extends State<OfferBookingSheet> {
  late OfferPrefillData _prefill;
  late TravelCity _selectedCity;
  late Airport _selectedOrigin;
  late Airport _selectedDestination;

  // Hotel Dates
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 4));
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;

  // Flight Dates
  DateTime _departureDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _returnDate = DateTime.now().add(const Duration(days: 14));
  bool _isRoundTrip = true;

  @override
  void initState() {
    super.initState();
    _prefill = OfferDestinationResolver.resolve(widget.offer);
    _selectedCity = _prefill.city;
    _selectedOrigin = _prefill.originAirport;
    _selectedDestination = _prefill.destinationAirport;

    // Automatically copy promo code if present
    if (widget.offer.code.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.offer.code));
    }
  }

  Future<void> _pickDate({
    required bool isArrivalOrReturn,
  }) async {
    final now = DateTime.now();
    if (_prefill.bookingType == OfferBookingType.hotel) {
      final initial = isArrivalOrReturn ? _checkIn : _checkOut;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (picked == null) return;
      setState(() {
        if (isArrivalOrReturn) {
          _checkIn = picked;
          if (!_checkOut.isAfter(picked)) {
            _checkOut = picked.add(const Duration(days: 1));
          }
        } else {
          if (picked.isAfter(_checkIn)) {
            _checkOut = picked;
          }
        }
      });
    } else {
      final initial = isArrivalOrReturn
          ? _departureDate
          : (_returnDate ?? _departureDate.add(const Duration(days: 7)));
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (picked == null) return;
      setState(() {
        if (isArrivalOrReturn) {
          _departureDate = picked;
          if (_returnDate != null && !_returnDate!.isAfter(picked)) {
            _returnDate = picked.add(const Duration(days: 3));
          }
        } else {
          if (picked.isAfter(_departureDate)) {
            _returnDate = picked;
          }
        }
      });
    }
  }

  Future<void> _changeCity() async {
    final city = await Navigator.push<TravelCity>(
      context,
      MaterialPageRoute(builder: (_) => const CityPickerPage()),
    );
    if (city != null) {
      setState(() => _selectedCity = city);
    }
  }

  Future<void> _changeAirport(bool isDestination) async {
    final airport = await Navigator.push<Airport>(
      context,
      MaterialPageRoute(builder: (_) => const AirportPickerPage()),
    );
    if (airport != null) {
      setState(() {
        if (isDestination) {
          _selectedDestination = airport;
        } else {
          _selectedOrigin = airport;
        }
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _onSearchPressed() {
    final app = AppControllerScope.of(context);
    final currency = app.currency;

    // Pop the booking sheet first
    Navigator.of(context).pop();

    // Show promo code applied reminder
    if (widget.offer.code.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${context.tr('appliedOffer')}: ${widget.offer.code}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.teal,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (_prefill.bookingType == OfferBookingType.hotel) {
      final search = HotelSearch(
        cityCode: _selectedCity.code,
        checkIn: _checkIn,
        checkOut: _checkOut,
        adults: _adults,
        children: _children,
        rooms: _rooms,
        currency: currency,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HotelResultsPage(search: search),
        ),
      );
    } else {
      final search = FlightSearch(
        origin: _selectedOrigin.code,
        destination: _selectedDestination.code,
        departure: _departureDate,
        returnDate: _isRoundTrip ? _returnDate : null,
        adults: _adults,
        children: _children,
        currency: currency,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlightResultsPage(search: search),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHotel = _prefill.bookingType == OfferBookingType.hotel;
    final nights = isHotel
        ? _checkOut.difference(_checkIn).inDays
        : (_returnDate != null ? _returnDate!.difference(_departureDate).inDays : 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161C26) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top drag bar & header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isHotel ? Icons.hotel_rounded : Icons.flight_takeoff_rounded,
                            color: AppColors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('bookOfferTitle'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF1E2633),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.tr(widget.offer.titleKey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Offer Banner Strip
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                      const Color(0xFFFF8F00).withValues(alpha: isDark ? 0.25 : 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.offer.formattedDiscount} ${context.tr('discountValue')} • ${context.tr('offerCode')}: ${widget.offer.code}',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr('activeOffer'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Form fields
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  children: [
                    // Destination Pre-fill Card
                    Text(
                      context.tr('destination'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),

                    if (isHotel) ...[
                      // Hotel Destination Card
                      InkWell(
                        onTap: _changeCity,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF222B3A)
                                : const Color(0xFFF3F6FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.orange.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.orange, AppColors.orangeLight],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.location_city_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _selectedCity.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? Colors.white : const Color(0xFF1E2633),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.orange.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            context.tr('offerDestinationPreFilled'),
                                            style: const TextStyle(
                                              color: AppColors.orange,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_selectedCity.country} • ${_selectedCity.code}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.swap_horiz_rounded,
                                color: AppColors.orange,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Flight Route Card
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _changeAirport(false),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF222B3A) : const Color(0xFFF3F6FA),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('from'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedOrigin.code,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF1E2633),
                                      ),
                                    ),
                                    Text(
                                      _selectedOrigin.city,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded, color: AppColors.orange, size: 20),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _changeAirport(true),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF222B3A) : const Color(0xFFF3F6FA),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.orange.withValues(alpha: 0.5),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('to'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedDestination.code,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF1E2633),
                                      ),
                                    ),
                                    Text(
                                      _selectedDestination.city,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Date Selection Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHotel ? context.tr('selectDatesForOffer') : context.tr('departure'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        if (nights > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$nights ${context.tr(nights == 1 ? 'night' : 'nights')}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!isHotel) ...[
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text(context.tr('roundTrip')),
                            selected: _isRoundTrip,
                            onSelected: (val) =>
                                setState(() => _isRoundTrip = true),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(context.tr('oneWay')),
                            selected: !_isRoundTrip,
                            onSelected: (val) =>
                                setState(() => _isRoundTrip = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    Row(
                      children: [
                        // Check-in / Departure
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(isArrivalOrReturn: true),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF222B3A) : const Color(0xFFF3F6FA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: AppColors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isHotel ? context.tr('checkIn') : context.tr('departure'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white54 : Colors.black45,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDate(isHotel ? _checkIn : _departureDate),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? Colors.white : const Color(0xFF1E2633),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Check-out / Return
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(isArrivalOrReturn: false),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF222B3A) : const Color(0xFFF3F6FA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.event_available_rounded,
                                    color: AppColors.teal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isHotel ? context.tr('checkOut') : context.tr('return'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white54 : Colors.black45,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isHotel
                                              ? _formatDate(_checkOut)
                                              : (_returnDate != null ? _formatDate(_returnDate!) : context.tr('oneWay')),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? Colors.white : const Color(0xFF1E2633),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Guests & Travelers Counter
                    Text(
                      isHotel ? context.tr('travelers') : context.tr('travelersAndCabin'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222B3A) : const Color(0xFFF3F6FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_alt_outlined, color: AppColors.orange, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                '$_adults ${context.tr(_adults == 1 ? 'adult' : 'adults')}${_children > 0 ? ' • $_children ${context.tr('children')}' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1E2633),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                iconSize: 22,
                                onPressed: _adults > 1 ? () => setState(() => _adults--) : null,
                              ),
                              Text(
                                '$_adults',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                iconSize: 22,
                                onPressed: _adults < 9 ? () => setState(() => _adults++) : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Children counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF222B3A)
                            : const Color(0xFFF3F6FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.child_care_rounded,
                                color: AppColors.teal,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$_children ${context.tr('children')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E2633),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                                iconSize: 22,
                                onPressed: _children > 0
                                    ? () => setState(() => _children--)
                                    : null,
                              ),
                              Text(
                                '$_children',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                iconSize: 22,
                                onPressed: _children < 6
                                    ? () => setState(() => _children++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (isHotel) ...[
                      const SizedBox(height: 8),
                      // Rooms counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF222B3A)
                              : const Color(0xFFF3F6FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.meeting_room_outlined,
                                  color: AppColors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$_rooms ${context.tr('rooms')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E2633),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                  ),
                                  iconSize: 22,
                                  onPressed: _rooms > 1
                                      ? () => setState(() => _rooms--)
                                      : null,
                                ),
                                Text(
                                  '$_rooms',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                  ),
                                  iconSize: 22,
                                  onPressed: _rooms < 5
                                      ? () => setState(() => _rooms++)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Search Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _onSearchPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isHotel
                                  ? '${context.tr('searchHotels')} (${_selectedCity.name})'
                                  : '${context.tr('searchFlights')} (${_selectedDestination.code})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
