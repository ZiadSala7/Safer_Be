import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../../core/widgets/travel_loading_view.dart';
import '../../../pricing/data/repositories/api_pricing_repository.dart';
import '../../../trips/data/repositories/api_trips_repository.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/hotel_booking.dart';
import '../../domain/entities/hotel_offer.dart';
import '../../domain/entities/hotel_room.dart';
import '../../domain/entities/hotel_search.dart';
import 'hotel_booking_status_page.dart';

class HotelBookingPage extends StatefulWidget {
  const HotelBookingPage({
    required this.offer,
    required this.search,
    super.key,
  });

  final HotelOffer offer;
  final HotelSearch search;

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  final repository = ApiTravelSearchRepository();
  final pricingRepository = ApiPricingRepository();
  final formKey = GlobalKey<FormState>();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final age = TextEditingController(text: '30');
  final email = TextEditingController();
  final phone = TextEditingController();
  final nationality = TextEditingController(text: 'SA');
  final couponController = TextEditingController();

  late Future<List<HotelRoom>> rooms = repository.hotelRooms(
    offer: widget.offer,
    search: widget.search,
  );
  HotelRoom? selectedRoom;
  String title = 'Mr';
  bool submitting = false;
  bool validatingCoupon = false;
  num discountAmount = 0;
  String? couponMessage;
  bool _loadingRooms = false;

  Future<void> openPayment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> applyCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) return;
    final currentPrice = selectedRoom?.price ?? widget.offer.totalPrice;
    setState(() => validatingCoupon = true);
    try {
      final result = await pricingRepository.validateCoupon(
        code,
        amount: currentPrice,
        productType: 'hotel',
      );
      setState(() {
        if (result.isValid) {
          discountAmount = result.discountAmount;
          couponMessage =
              'Saved ${result.discountAmount} ${widget.offer.currency}!';
        } else {
          discountAmount = 0;
          couponMessage =
              result.message.isNotEmpty ? result.message : 'Invalid coupon';
        }
      });
    } catch (_) {
      setState(() {
        discountAmount = 0;
        couponMessage = 'Invalid coupon code';
      });
    } finally {
      setState(() => validatingCoupon = false);
    }
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    age.dispose();
    email.dispose();
    phone.dispose();
    nationality.dispose();
    couponController.dispose();
    super.dispose();
  }

  Future<List<HotelRoom>> reloadRooms() async {
    setState(() {
      _loadingRooms = true;
    });
    final nextRooms = repository.hotelRooms(
      offer: widget.offer,
      search: widget.search,
    );
    setState(() {
      rooms = nextRooms;
    });
    try {
      final res = await nextRooms;
      return res;
    } finally {
      if (mounted) {
        setState(() {
          _loadingRooms = false;
        });
      }
    }
  }

  Future<void> _openRoomPickerSheet(
    BuildContext context,
    List<HotelRoom> availableRooms,
  ) async {
    final picked = await showModalBottomSheet<HotelRoom>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoomSelectionModalSheet(
        rooms: availableRooms,
        currentlySelected: selectedRoom ?? availableRooms.first,
        currency: widget.offer.currency,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedRoom = picked;
      });
      // Re-validate coupon if discount was applied
      if (couponController.text.trim().isNotEmpty && discountAmount > 0) {
        applyCoupon();
      }
    }
  }

  Future<void> submit(List<HotelRoom> availableRooms) async {
    final room = selectedRoom ?? availableRooms.firstOrNull;
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('chooseAvailableRoom'))),
      );
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    try {
      final request = HotelBookingRequest(
        hotelCode: widget.offer.code,
        supplier: widget.offer.supplier.isNotEmpty
            ? widget.offer.supplier
            : 'juniper',
        checkIn: widget.search.checkIn,
        checkOut: widget.search.checkOut,
        currency: widget.offer.currency,
        room: room,
        guest: HotelBookingGuest(
          title: title,
          firstName: firstName.text.trim(),
          lastName: lastName.text.trim(),
          age: int.tryParse(age.text.trim()) ?? 30,
        ),
        email: email.text.trim(),
        phone: phone.text.trim(),
        nationality: nationality.text.trim().toUpperCase(),
        callbackUrl: 'https://frontend.saferbe.com/payment/success',
        errorUrl: 'https://frontend.saferbe.com/payment/failed',
      );

      String reference = '';
      String paymentUrl = '';

      try {
        final checkout = await repository.initiateHotelCheckout(request);
        reference = checkout.bookingReference;
        paymentUrl = checkout.paymentUrl;
      } catch (_) {
        final legacy = await repository.bookHotel(request);
        reference = legacy.reference;
      }

      if (!mounted) return;

      final tripsRepo = ApiTripsRepository();
      await tripsRepo.saveTrip(
        Trip(
          route: widget.offer.name,
          date: widget.search.checkIn.toIso8601String().split('T').first,
          provider: widget.offer.supplier.isNotEmpty
              ? widget.offer.supplier.toUpperCase()
              : 'Hotel',
          reference: reference,
          type: 'hotel',
          status: 'pending',
        ),
      );

      if (!mounted) return;

      if (paymentUrl.isNotEmpty) {
        await openPayment(paymentUrl);
      }

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => HotelBookingStatusPage(
            bookingReference: reference,
            paymentUrl: paymentUrl.isNotEmpty ? paymentUrl : null,
            hotelName: widget.offer.name,
            supplier: widget.offer.supplier,
            price: room.price,
            currency: widget.offer.currency,
            checkIn: widget.search.checkIn,
            checkOut: widget.search.checkOut,
            roomName: room.name,
          ),
        ),
      );
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$exception')));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? context.tr('required') : null;

  String? requiredEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return context.tr('required');
    if (!text.contains('@')) return context.tr('validEmail');
    return null;
  }

  String? requiredAge(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1 || parsed > 120) {
      return context.tr('validAge');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        context.tr('bookStayTitle'),
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
      ),
    ),
    body: FutureBuilder<List<HotelRoom>>(
      future: rooms,
      builder: (context, snapshot) {
        if (_loadingRooms || snapshot.connectionState != ConnectionState.done) {
          return TravelLoadingView(
            icon: Icons.meeting_room_outlined,
            badge: widget.offer.name,
            title: context.tr('checkingRooms'),
            subtitle: context.tr('lookingForLiveRooms'),
          );
        }
        if (snapshot.hasError) {
          return RequestStateView(
            icon: Icons.cloud_off_rounded,
            title: context.tr('roomsUnavailable'),
            message: '${snapshot.error}',
            actionLabel: context.tr('tryAgain'),
            onAction: reloadRooms,
          );
        }
        final availableRooms = snapshot.data ?? const [];
        if (availableRooms.isEmpty) {
          return RequestStateView(
            icon: Icons.bed_outlined,
            title: context.tr('noRoomsFound'),
            message: context.tr('tryAnotherStayDates'),
            actionLabel: context.tr('backToStay'),
            onAction: () => Navigator.pop(context),
          );
        }

        final currentRoom = selectedRoom ?? availableRooms.first;
        final roomFinalPrice = (currentRoom.price - discountAmount > 0)
            ? (currentRoom.price - discountAmount)
            : currentRoom.price;

        return Scaffold(
          bottomNavigationBar: _HotelBookingFareBar(
            price: roomFinalPrice,
            currency: widget.offer.currency,
            submitting: submitting,
            onSubmit: () => submit(availableRooms),
          ),
          body: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Stay Summary Header Card
                _StaySummaryHeader(
                  offer: widget.offer,
                  search: widget.search,
                ),
                const SizedBox(height: 18),

                // ROOM SELECTION DROPDOWN SECTION (Compact & Expandable Dropdown)
                _SelectedRoomDropdownCard(
                  selectedRoom: currentRoom,
                  availableCount: availableRooms.length,
                  currency: widget.offer.currency,
                  onTapChange: () => _openRoomPickerSheet(context, availableRooms),
                ),
                const SizedBox(height: 20),

                // LEAD GUEST DETAILS SECTION
                _FormSectionCard(
                  icon: Icons.person_outline_rounded,
                  title: context.tr('leadGuestDetails'),
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: title,
                      decoration: InputDecoration(
                        labelText: context.tr('title'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      items: const ['Mr', 'Ms', 'Mrs', 'Miss', 'Dr']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(context.tr('title$value')),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => title = value ?? title),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstName,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: context.tr('firstName'),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: requiredText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: lastName,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: context.tr('lastName'),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: requiredText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: age,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.tr('age'),
                        prefixIcon: const Icon(Icons.cake_outlined),
                      ),
                      validator: requiredAge,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // CONTACT INFORMATION SECTION
                _FormSectionCard(
                  icon: Icons.contact_mail_outlined,
                  title: context.tr('contact'),
                  children: [
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.tr('email'),
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: requiredEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.tr('phone'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: requiredText,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nationality,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: context.tr('nationalityCode'),
                        hintText: 'SA',
                        prefixIcon: const Icon(Icons.flag_outlined),
                      ),
                      validator: requiredText,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // PROMO CODE & COUPON SECTION
                _FormSectionCard(
                  icon: Icons.local_offer_outlined,
                  title: context.tr('promoCode'),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'PROMO2026',
                              prefixIcon: Icon(Icons.confirmation_number_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: validatingCoupon ? null : applyCoupon,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            minimumSize: const Size(86, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: validatingCoupon
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.tr('apply'),
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ],
                    ),
                    if (couponMessage != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            discountAmount > 0
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            size: 16,
                            color: discountAmount > 0 ? AppColors.teal : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            couponMessage!,
                            style: TextStyle(
                              color: discountAmount > 0 ? AppColors.teal : Colors.red,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),

                // PRICE BREAKDOWN SUMMARY CARD
                _HotelPriceBreakdownCard(
                  room: currentRoom,
                  currency: widget.offer.currency,
                  discount: discountAmount,
                  nights: widget.search.checkOut
                      .difference(widget.search.checkIn)
                      .inDays,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _StaySummaryHeader extends StatelessWidget {
  const _StaySummaryHeader({required this.offer, required this.search});

  final HotelOffer offer;
  final HotelSearch search;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  @override
  Widget build(BuildContext context) {
    final nights = search.checkOut.difference(search.checkIn).inDays;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.navy, AppColors.navySoft]
              : [const Color(0xFF0F365E), AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  offer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderItem(
                icon: Icons.calendar_today_rounded,
                label: '${_date(context, search.checkIn)} - ${_date(context, search.checkOut)}',
              ),
              _HeaderItem(
                icon: Icons.nights_stay_rounded,
                label: '$nights ${context.tr(nights == 1 ? 'night' : 'nights')}',
              ),
            ],
          ),
          const SizedBox(height: 6),
          _HeaderItem(
            icon: Icons.people_alt_outlined,
            label: '${search.adults} ${context.tr(search.adults == 1 ? 'adult' : 'adults')}${search.children > 0 ? ', ${search.children} ${context.tr('children')}' : ''}',
          ),
        ],
      ),
    );
  }
}

class _HeaderItem extends StatelessWidget {
  const _HeaderItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Colors.white70),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SelectedRoomDropdownCard extends StatelessWidget {
  const _SelectedRoomDropdownCard({
    required this.selectedRoom,
    required this.availableCount,
    required this.currency,
    required this.onTapChange,
  });

  final HotelRoom selectedRoom;
  final int availableCount;
  final String currency;
  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bed_rounded,
                  color: AppColors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('selectedRoom'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$availableCount ${context.tr('roomOptionsAvailable')}',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Interactive Selected Room Banner
          InkWell(
            onTap: onTapChange,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedRoom.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _RoomTag(
                              label: _mealPlan(context, selectedRoom.mealPlan),
                              color: AppColors.teal,
                            ),
                            _RoomTag(
                              label: context.tr(
                                selectedRoom.refundable
                                    ? 'refundable'
                                    : 'nonRefundable',
                              ),
                              color: selectedRoom.refundable
                                  ? AppColors.teal
                                  : AppColors.orange,
                            ),
                          ],
                        ),
                        if (selectedRoom.cancellationPolicy.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            selectedRoom.cancellationPolicy,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        selectedRoom.price > 0
                            ? '${selectedRoom.price.toStringAsFixed(2)} $currency'
                            : currency,
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('changeRoom'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _mealPlan(BuildContext context, String code) {
    switch (code.toUpperCase()) {
      case 'RO':
        return context.tr('roomOnly');
      case 'BB':
        return context.tr('breakfast');
      case 'HB':
        return context.tr('halfBoard');
      case 'FB':
        return context.tr('fullBoard');
      case 'AI':
        return context.tr('allInclusive');
      default:
        return code;
    }
  }
}

class _RoomTag extends StatelessWidget {
  const _RoomTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    ),
  );
}

class _RoomSelectionModalSheet extends StatefulWidget {
  const _RoomSelectionModalSheet({
    required this.rooms,
    required this.currentlySelected,
    required this.currency,
  });

  final List<HotelRoom> rooms;
  final HotelRoom currentlySelected;
  final String currency;

  @override
  State<_RoomSelectionModalSheet> createState() =>
      _RoomSelectionModalSheetState();
}

class _RoomSelectionModalSheetState extends State<_RoomSelectionModalSheet> {
  late HotelRoom _tempSelected = widget.currentlySelected;
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredRooms = widget.rooms.where((room) {
      if (_filterQuery.isEmpty) return true;
      return room.name.toLowerCase().contains(_filterQuery.toLowerCase()) ||
          room.mealPlan.toLowerCase().contains(_filterQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle pill
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // Header title & count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room_rounded, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('chooseRoomType'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Filter
            if (widget.rooms.length > 5) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  onChanged: (val) => setState(() => _filterQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: context.tr('roomDetails'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],

            const Divider(height: 12),

            // Room Options List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filteredRooms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final room = filteredRooms[index];
                  final isSelected = _tempSelected.code == room.code;

                  return InkWell(
                    onTap: () {
                      setState(() => _tempSelected = room);
                      Navigator.pop(context, room);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.teal
                              : Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.25),
                          width: isSelected ? 1.8 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.teal.withValues(
                                    alpha: isDark ? 0.2 : 0.08,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? AppColors.teal : AppColors.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                    color: isSelected ? AppColors.teal : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _RoomTag(
                                      label: _SelectedRoomDropdownCard._mealPlan(
                                        context,
                                        room.mealPlan,
                                      ),
                                      color: AppColors.teal,
                                    ),
                                    _RoomTag(
                                      label: context.tr(
                                        room.refundable
                                            ? 'refundable'
                                            : 'nonRefundable',
                                      ),
                                      color: room.refundable
                                          ? AppColors.teal
                                          : AppColors.orange,
                                    ),
                                  ],
                                ),
                                if (room.cancellationPolicy.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    room.cancellationPolicy,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            room.price > 0
                                ? '${room.price.toStringAsFixed(2)} ${widget.currency}'
                                : widget.currency,
                            style: TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.teal, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ],
        ),
        const Divider(height: 22),
        ...children,
      ],
    ),
  );
}

class _HotelPriceBreakdownCard extends StatelessWidget {
  const _HotelPriceBreakdownCard({
    required this.room,
    required this.currency,
    required this.discount,
    required this.nights,
  });

  final HotelRoom room;
  final String currency;
  final num discount;
  final int nights;

  @override
  Widget build(BuildContext context) {
    final finalTotal = (room.price - discount > 0) ? (room.price - discount) : room.price;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                context.tr('priceBreakdown'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 22),
          _PriceLine(
            label: '${context.tr('roomRate')} ($nights ${context.tr(nights == 1 ? 'night' : 'nights')})',
            value: '${room.price.toStringAsFixed(2)} $currency',
          ),
          const SizedBox(height: 8),
          _PriceLine(
            label: context.tr('taxesAndFees'),
            value: context.tr('includedInPrice'),
            isPositive: true,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _PriceLine(
              label: context.tr('discountApplied'),
              value: '-${discount.toStringAsFixed(2)} $currency',
              isDiscount: true,
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('totalPayable'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                '${finalTotal.toStringAsFixed(2)} $currency',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.isPositive = false,
    this.isDiscount = false,
  });

  final String label;
  final String value;
  final bool isPositive;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: isDiscount
              ? Colors.red
              : (isPositive ? AppColors.teal : null),
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    ],
  );
}

class _HotelBookingFareBar extends StatelessWidget {
  const _HotelBookingFareBar({
    required this.price,
    required this.currency,
    required this.submitting,
    required this.onSubmit,
  });

  final num price;
  final String currency;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('totalPayable'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${price.toStringAsFixed(2)} $currency',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified_outlined, size: 20),
              label: Text(
                context.tr(
                  submitting ? 'sendingRequest' : 'confirmBookingRequest',
                ),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
