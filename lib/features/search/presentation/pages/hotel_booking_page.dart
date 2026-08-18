import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../pricing/data/repositories/api_pricing_repository.dart';
import '../../../trips/data/repositories/api_trips_repository.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/hotel_booking.dart';
import '../../domain/entities/hotel_offer.dart';
import '../../domain/entities/hotel_room.dart';
import '../../domain/entities/hotel_search.dart';

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

  Future<void> applyCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) return;
    setState(() => validatingCoupon = true);
    try {
      final result = await pricingRepository.validateCoupon(
        code,
        amount: widget.offer.totalPrice,
        productType: 'hotel',
      );
      setState(() {
        if (result.isValid) {
          discountAmount = result.discountAmount;
          couponMessage = 'Saved ${result.discountAmount} ${widget.offer.currency}!';
        } else {
          discountAmount = 0;
          couponMessage = result.message.isNotEmpty ? result.message : 'Invalid coupon';
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
    super.dispose();
  }

  Future<List<HotelRoom>> reloadRooms() {
    final nextRooms = repository.hotelRooms(
      offer: widget.offer,
      search: widget.search,
    );
    setState(() {
      rooms = nextRooms;
    });
    return nextRooms;
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
        checkIn: widget.search.checkIn,
        checkOut: widget.search.checkOut,
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
      );

      String reference = '';
      String message = '';
      String paymentUrl = '';

      try {
        final checkout = await repository.initiateHotelCheckout(request);
        reference = checkout.bookingReference;
        paymentUrl = checkout.paymentUrl;
        message = checkout.message;
      } catch (_) {
        final legacy = await repository.bookHotel(request);
        reference = legacy.reference;
        message = legacy.message;
      }

      if (!mounted) return;

      final tripsRepo = ApiTripsRepository();
      await tripsRepo.saveTrip(
        Trip(
          route: widget.offer.name,
          date: widget.search.checkIn.toIso8601String().split('T').first,
          provider: 'Hotel',
          reference: reference,
          type: 'hotel',
          status: 'pending',
        ),
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.verified_rounded, color: AppColors.teal),
          title: Text(context.tr(paymentUrl.isNotEmpty ? 'checkoutInitiated' : 'bookingRequestSent')),
          content: Text(
            reference.isEmpty
                ? message
                : '$message\n\n${context.tr('reference')}: $reference',
          ),
          actions: [
            if (paymentUrl.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.payment_rounded),
                label: Text(context.tr('payNow')),
                style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('done')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
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
    appBar: AppBar(title: Text(context.tr('bookStayTitle'))),
    body: FutureBuilder<List<HotelRoom>>(
      future: rooms,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return RequestStateView(
            icon: Icons.meeting_room_outlined,
            title: context.tr('checkingRooms'),
            message: context.tr('lookingForLiveRooms'),
            loading: true,
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
        return Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _BookingHeader(offer: widget.offer, search: widget.search),
              const SizedBox(height: 18),
              Text(
                context.tr('chooseRoom'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...availableRooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RoomOption(
                    room: room,
                    selected:
                        (selectedRoom?.code ?? availableRooms.first.code) ==
                        room.code,
                    onTap: () => setState(() => selectedRoom = room),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('leadGuest'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
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
              TextFormField(
                controller: firstName,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('firstName'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: requiredText,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lastName,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('lastName'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: requiredText,
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
              const SizedBox(height: 18),
              Text(
                context.tr('contact'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 18),
              Text(
                context.tr('promoCode'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'PROMO2026',
                        prefixIcon: Icon(Icons.local_offer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: validatingCoupon ? null : applyCoupon,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size(80, 52),
                    ),
                    child: validatingCoupon
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.tr('apply')),
                  ),
                ],
              ),
              if (couponMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  couponMessage!,
                  style: TextStyle(
                    color: discountAmount > 0 ? AppColors.teal : Colors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: submitting ? null : () => submit(availableRooms),
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(
                    context.tr(
                      submitting ? 'sendingRequest' : 'confirmBookingRequest',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.offer, required this.search});

  final HotelOffer offer;
  final HotelSearch search;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  @override
  Widget build(BuildContext context) {
    final nights = search.checkOut.difference(search.checkIn).inDays;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navySoft, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_date(context, search.checkIn)} - ${_date(context, search.checkOut)}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            '$nights ${context.tr(nights == 1 ? 'night' : 'nights')} - 2 ${context.tr('adults')}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _RoomOption extends StatelessWidget {
  const _RoomOption({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  final HotelRoom room;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppColors.teal
              : Theme.of(context).dividerColor.withValues(alpha: .35),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? AppColors.teal : AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_mealPlan(context, room.mealPlan)} - ${context.tr(room.refundable ? 'refundable' : 'nonRefundable')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (room.cancellationPolicy.isNotEmpty)
                  Text(
                    room.cancellationPolicy,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            room.price > 0
                ? '${room.price.toStringAsFixed(2)} ${room.currency}'
                : room.currency,
            style: const TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );

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
