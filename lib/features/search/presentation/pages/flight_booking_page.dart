import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../pricing/data/repositories/api_pricing_repository.dart';
import '../../../trips/data/repositories/api_trips_repository.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/pages/flight_booking_details_page.dart';
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
    couponController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (widget.offer.isQuoteExpired) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.event_busy_rounded,
            color: AppColors.orange,
            size: 28,
          ),
          title: Text(context.tr('ticketUnavailable')),
          content: Text(context.tr('ticketUnavailableBody')),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              child: Text(context.tr('searchAgain')),
            ),
          ],
        ),
      );
      return;
    }

    final app = AppControllerScope.of(context);
    if (!app.showPaymentGatewayMobile) {
      AppWhatsAppHelper.launchFlightInquiry(
        context: context,
        offer: widget.offer,
        search: widget.search,
      );
      return;
    }

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

      final code = couponController.text.trim();
      final request = FlightBookingRequest(
        resultIndex: widget.offer.referenceIndex ??
            widget.offer.resultIndex ??
            widget.offer.id,
        supplier: widget.offer.supplier ?? 'tbo',
        searchId: widget.offer.searchId ?? widget.search.searchId,
        currency: widget.offer.currency,
        journeyType: widget.search.journeyType,
        flightData: widget.offer.toFlightDataMap(widget.search),
        passengers: passengers,
        promoCode: code.isNotEmpty ? code.toUpperCase() : null,
      );

      String bookingRef = '';
      String pnr = '';
      String paymentUrl = '';
      String status = 'pending';

      final isFree = AppControllerScope.of(context).isFreePurchase;

      if (isFree) {
        final legacy = await repository.bookFlight(request);
        bookingRef = legacy.bookingReference;
        pnr = legacy.pnr;
        status = legacy.status.isNotEmpty ? legacy.status : 'confirmed';
      } else {
        final checkout = await repository.initiateFlightCheckout(request);
        bookingRef = checkout.bookingReference;
        paymentUrl = checkout.paymentUrl;
      }

      if (!mounted) return;

      // Save trip locally
      final primaryRef = bookingRef.isNotEmpty ? bookingRef : pnr;
      final legRoute = widget.offer.route.isNotEmpty
          ? widget.offer.route
          : '${widget.search.origin} → ${widget.search.destination}';
      final tripsRepo = ApiTripsRepository();
      await tripsRepo.saveTrip(
        Trip(
          route: legRoute,
          date: widget.search.departure.toIso8601String().split('T').first,
          provider: widget.offer.airline,
          reference: primaryRef,
          pnr: pnr,
          type: 'flight',
          status: status,
          price: widget.offer.price,
          currency: widget.offer.currency,
        ),
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.flight_takeoff_rounded, color: AppColors.teal, size: 30),
          title: Text(
            context.tr(
              paymentUrl.isNotEmpty ? 'checkoutInitiated' : 'flightBooked',
            ),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paymentUrl.isNotEmpty
                    ? context.tr('pleaseCompletePayment')
                    : context.tr('flightBookedDesc'),
                style: const TextStyle(height: 1.3),
              ),
              if (pnr.isNotEmpty) ...[
                const SizedBox(height: 14),
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
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (primaryRef.isNotEmpty)
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // pop dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => FlightBookingDetailsPage(
                        bookingReference: primaryRef,
                      ),
                    ),
                  );
                },
                child: Text(context.tr('flightDetailsTitle')),
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
    } on ApiException catch (exception) {
      if (!mounted) return;
      if (exception.isValidationError) {
        final isPromoError = exception.errors.containsKey('promo_code') ||
            exception.message.toLowerCase().contains('promo') ||
            exception.message.toLowerCase().contains('coupon') ||
            exception.message.toLowerCase().contains('code');
        if (isPromoError && couponController.text.isNotEmpty) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(
                Icons.local_offer_outlined,
                color: AppColors.orange,
                size: 28,
              ),
              title: Text(context.tr('invalidPromoTitle')),
              content: Text(exception.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.tr('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      couponController.clear();
                      discountAmount = 0;
                      couponMessage = null;
                    });
                    submit();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(context.tr('clearPromoAndContinue')),
                ),
              ],
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.message)),
        );
      } else if (exception.isExpiredSession ||
          exception.isNotFound ||
          exception.statusCode == 410) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(
              Icons.event_busy_rounded,
              color: AppColors.orange,
              size: 28,
            ),
            title: Text(context.tr('ticketUnavailable')),
            content: Text(context.tr('ticketUnavailableBody')),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                child: Text(context.tr('searchAgain')),
              ),
            ],
          ),
        );
      } else if (exception.isPriceConflict) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(
              Icons.price_change_outlined,
              color: AppColors.orange,
              size: 28,
            ),
            title: Text(context.tr('fareChanged')),
            content: Text(
              exception.oldPrice != null && exception.newPrice != null
                  ? '${exception.oldPrice} -> ${exception.newPrice} ${widget.offer.currency}'
                  : exception.message,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
                child: Text(context.tr('searchAgain')),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.message)),
        );
      }
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
  Widget build(BuildContext context) {
    final totalTravelers =
        widget.search.adults + widget.search.children + widget.search.infants;
    final finalPrice = (widget.offer.price - discountAmount > 0)
        ? (widget.offer.price - discountAmount)
        : widget.offer.price;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('flightBooking'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      bottomNavigationBar: _FlightBookingBottomBar(
        totalFare: finalPrice,
        currency: widget.offer.currency,
        submitting: submitting,
        onSubmit: submit,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Flight Summary Header Card
            _FlightBookingSummaryHeader(
              offer: widget.offer,
              search: widget.search,
              totalTravelers: totalTravelers,
            ),
            const SizedBox(height: 18),

            // PASSENGER DETAILS CARD
            _BookingSectionCard(
              icon: Icons.person_outline_rounded,
              title: context.tr('passengerDetails'),
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
                          child: Text(value),
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
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: InputDecoration(
                    labelText: context.tr('gender'),
                    prefixIcon: const Icon(Icons.wc_outlined),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '1',
                      child: Text(context.tr('male')),
                    ),
                    DropdownMenuItem(
                      value: '2',
                      child: Text(context.tr('female')),
                    ),
                  ],
                  onChanged: (value) => setState(() => gender = value ?? gender),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // TRAVEL DOCUMENTS CARD
            _BookingSectionCard(
              icon: Icons.assignment_ind_outlined,
              title: context.tr('travelDocuments'),
              children: [
                TextFormField(
                  controller: passportNumber,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
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
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    suffixIcon: const Icon(Icons.edit_calendar_rounded, size: 20),
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
              ],
            ),
            const SizedBox(height: 18),

            // CONTACT INFORMATION CARD
            _BookingSectionCard(
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
                  controller: address,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: context.tr('address'),
                    prefixIcon: const Icon(Icons.home_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // PROMO CODE & COUPON CARD
            _BookingSectionCard(
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

            // FARE BREAKDOWN CARD
            _FlightFareBreakdownCard(
              offer: widget.offer,
              totalTravelers: totalTravelers,
              discount: discountAmount,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightBookingSummaryHeader extends StatelessWidget {
  const _FlightBookingSummaryHeader({
    required this.offer,
    required this.search,
    required this.totalTravelers,
  });

  final FlightOffer offer;
  final FlightSearch search;
  final int totalTravelers;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  String _duration() {
    if (offer.durationMinutes <= 0) return '--';
    final hours = offer.durationMinutes ~/ 60;
    final minutes = offer.durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final origin = offer.origin.isNotEmpty ? offer.origin : search.origin;
    final destination =
        offer.destination.isNotEmpty ? offer.destination : search.destination;

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
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.airline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (offer.cabinClass.isNotEmpty)
                      Text(
                        offer.cabinClass,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AirportPoint(
                  code: origin,
                  label: context.tr('from'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Icon(
                      Icons.east_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _duration(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _AirportPoint(
                  code: destination,
                  label: context.tr('to'),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _date(context, search.departure),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.people_alt_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$totalTravelers ${context.tr(totalTravelers == 1 ? 'traveler' : 'travelers')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (offer.expiresIn != null && offer.expiresIn! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('priceLockGuaranteed'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AirportPoint extends StatelessWidget {
  const _AirportPoint({
    required this.code,
    required this.label,
    this.alignEnd = false,
  });

  final String code;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        code,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _BookingSectionCard extends StatelessWidget {
  const _BookingSectionCard({
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

class _FlightFareBreakdownCard extends StatelessWidget {
  const _FlightFareBreakdownCard({
    required this.offer,
    required this.totalTravelers,
    required this.discount,
  });

  final FlightOffer offer;
  final int totalTravelers;
  final num discount;

  @override
  Widget build(BuildContext context) {
    final finalTotal = (offer.price - discount > 0)
        ? (offer.price - discount)
        : offer.price;

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
          _FareLine(
            label: '${context.tr('baseFare')} ($totalTravelers ${context.tr(totalTravelers == 1 ? 'traveler' : 'travelers')})',
            value: '${offer.price.toStringAsFixed(2)} ${offer.currency}',
          ),
          const SizedBox(height: 8),
          _FareLine(
            label: context.tr('taxesAndFees'),
            value: context.tr('includedInPrice'),
            isPositive: true,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _FareLine(
              label: context.tr('discountApplied'),
              value: '-${discount.toStringAsFixed(2)} ${offer.currency}',
              isDiscount: true,
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('totalFare'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                '${finalTotal.toStringAsFixed(2)} ${offer.currency}',
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

class _FareLine extends StatelessWidget {
  const _FareLine({
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

class _FlightBookingBottomBar extends StatelessWidget {
  const _FlightBookingBottomBar({
    required this.totalFare,
    required this.currency,
    required this.submitting,
    required this.onSubmit,
  });

  final num totalFare;
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
      child: AppControllerScope.of(context).showPaymentGatewayMobile
          ? Row(
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
                        '${totalFare.toStringAsFixed(2)} $currency',
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
                        : const Icon(Icons.flight_rounded, size: 20),
                    label: Text(
                      context.tr(
                        submitting ? 'bookingFlight' : 'confirmFlightBooking',
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
            )
          : WhatsAppBookingButton(
              height: 52,
              onPressed: onSubmit,
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
        style: TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    ],
  );
}
