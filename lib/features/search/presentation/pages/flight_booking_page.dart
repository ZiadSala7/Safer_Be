import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pricing/data/repositories/api_pricing_repository.dart';
import '../../../trips/data/repositories/api_trips_repository.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/flight_booking.dart';
import '../../domain/entities/flight_offer.dart';
import '../../domain/entities/flight_search.dart';

class FlightBookingPage extends StatefulWidget {
  const FlightBookingPage({
    required this.offer,
    required this.search,
    super.key,
  });

  final FlightOffer offer;
  final FlightSearch search;

  @override
  State<FlightBookingPage> createState() => _FlightBookingPageState();
}

class _FlightBookingPageState extends State<FlightBookingPage> {
  final repository = ApiTravelSearchRepository();
  final pricingRepository = ApiPricingRepository();
  final formKey = GlobalKey<FormState>();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final passportNumber = TextEditingController();
  final passportExpiry = TextEditingController();
  final nationality = TextEditingController(text: 'SA');
  final address = TextEditingController();
  final couponController = TextEditingController();

  String title = 'Mr';
  String gender = '1';
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
        amount: widget.offer.price,
        productType: 'flight',
      );
      setState(() {
        if (result.isValid) {
          discountAmount = result.discountAmount;
          couponMessage =
              'Saved ${result.discountAmount} ${widget.offer.currency}!';
        } else {
          discountAmount = 0;
          couponMessage = result.message.isNotEmpty
              ? result.message
              : 'Invalid coupon';
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

  Future<void> openPayment(String paymentUrl) async {
    final uri = Uri.tryParse(paymentUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('paymentUrlUnavailable'))),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('paymentUrlUnavailable'))),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final futureDate = DateTime.now().add(const Duration(days: 365 * 3));
    passportExpiry.text =
        '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    passportNumber.dispose();
    passportExpiry.dispose();
    nationality.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    try {
      final passengers = <FlightBookingPassenger>[
        FlightBookingPassenger(
          title: title,
          firstName: firstName.text.trim(),
          lastName: lastName.text.trim(),
          type: 'adult',
          dateOfBirth: '1990-01-01',
          passportNumber: passportNumber.text.trim(),
          passportExpiry: passportExpiry.text.trim(),
          nationality: nationality.text.trim().toUpperCase(),
          email: email.text.trim(),
          phone: phone.text.trim(),
          gender: gender,
          isLeadPassenger: true,
          address: address.text.trim(),
        ),
      ];

      final request = FlightBookingRequest(
        resultIndex: widget.offer.resultIndex ?? widget.offer.id,
        supplier: widget.offer.supplier ?? 'tbo',
        searchId: widget.offer.searchId ?? widget.search.searchId,
        currency: widget.offer.currency,
        flightData: widget.offer.toFlightDataMap(widget.search),
        passengers: passengers,
      );

      String bookingRef = '';
      String pnr = '';
      String paymentUrl = '';
      String status = 'pending';

      try {
        final checkout = await repository.initiateFlightCheckout(request);
        bookingRef = checkout.bookingReference;
        paymentUrl = checkout.paymentUrl;
      } catch (_) {
        // Fallback to legacy book endpoint
        final legacy = await repository.bookFlight(request);
        bookingRef = legacy.bookingReference;
        pnr = legacy.pnr;
        status = legacy.status;
      }

      if (!mounted) return;

      // Save trip locally
      final tripsRepo = ApiTripsRepository();
      await tripsRepo.saveTrip(
        Trip(
          route: '${widget.search.origin} → ${widget.search.destination}',
          date: widget.search.departure.toIso8601String().split('T').first,
          provider: widget.offer.airline,
          reference: pnr.isNotEmpty ? pnr : bookingRef,
          type: 'flight',
          status: status,
        ),
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.flight_takeoff_rounded, color: AppColors.teal),
          title: Text(
            context.tr(
              paymentUrl.isNotEmpty ? 'checkoutInitiated' : 'flightBooked',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paymentUrl.isNotEmpty
                    ? context.tr('pleaseCompletePayment')
                    : context.tr('flightBookedDesc'),
              ),
              if (pnr.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(label: context.tr('pnr'), value: pnr),
              ],
              if (bookingRef.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(label: context.tr('reference'), value: bookingRef),
              ],
            ],
          ),
          actions: [
            if (paymentUrl.isNotEmpty)
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await openPayment(paymentUrl);
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.payment_rounded),
                label: Text(context.tr('payNow')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(context.tr('done')),
            ),
          ],
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('flightBooking'))),
    bottomNavigationBar: _FlightFareBar(
      offer: widget.offer,
      submitting: submitting,
      onSubmit: submit,
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _FlightSummaryCard(offer: widget.offer, search: widget.search),
          const SizedBox(height: 22),
          Text(
            context.tr('passengerDetails'),
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
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
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
          DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: InputDecoration(
              labelText: context.tr('gender'),
              prefixIcon: const Icon(Icons.wc_outlined),
            ),
            items: [
              DropdownMenuItem(value: '1', child: Text(context.tr('male'))),
              DropdownMenuItem(value: '2', child: Text(context.tr('female'))),
            ],
            onChanged: (value) => setState(() => gender = value ?? gender),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('travelDocuments'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: passportNumber,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.tr('passportNumber'),
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
            ),
            validator: requiredText,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passportExpiry,
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 365 * 3)),
                firstDate: DateTime.now().add(const Duration(days: 180)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 15)),
              );
              if (picked != null) {
                passportExpiry.text =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              }
            },
            decoration: InputDecoration(
              labelText: context.tr('passportExpiry'),
              hintText: 'YYYY-MM-DD',
              prefixIcon: const Icon(Icons.event_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return context.tr('required');
              }
              final parsed = DateTime.tryParse(val.trim());
              if (parsed == null || !parsed.isAfter(DateTime.now())) {
                return 'Passport expiry must be a date after today';
              }
              return null;
            },
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
            controller: address,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: context.tr('address'),
              prefixIcon: const Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('promoCode'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
        ],
      ),
    ),
  );
}

class _FlightSummaryCard extends StatelessWidget {
  const _FlightSummaryCard({required this.offer, required this.search});

  final FlightOffer offer;
  final FlightSearch search;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  String _duration() {
    if (offer.durationMinutes <= 0) return '--';
    final hours = offer.durationMinutes ~/ 60;
    final minutes = offer.durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) => Container(
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
        Row(
          children: [
            const Icon(Icons.flight_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                offer.airline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _AirportPill(code: search.origin, label: context.tr('from')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Icon(
                    Icons.east_rounded,
                    color: Colors.white.withValues(alpha: .7),
                    size: 18,
                  ),
                  Text(
                    _duration(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _AirportPill(
              code: search.destination,
              label: context.tr('to'),
              alignEnd: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: Colors.white.withValues(alpha: .7),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _date(context, search.departure),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${offer.price.toStringAsFixed(0)} ${offer.currency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AirportPill extends StatelessWidget {
  const _AirportPill({
    required this.code,
    required this.label,
    this.alignEnd = false,
  });

  final String code;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          code,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _FlightFareBar extends StatelessWidget {
  const _FlightFareBar({
    required this.offer,
    required this.submitting,
    required this.onSubmit,
  });

  final FlightOffer offer;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: .35),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('totalFare'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${offer.price.toStringAsFixed(2)} ${offer.currency}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            height: 50,
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
                  : const Icon(Icons.flight_rounded, size: 19),
              label: Text(
                submitting
                    ? context.tr('bookingFlight')
                    : context.tr('confirmFlightBooking'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        '$label: ',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      ),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    ],
  );
}
