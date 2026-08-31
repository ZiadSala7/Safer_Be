import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../support/presentation/pages/safer_be_support_chat_sheet.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/flight_offer.dart';
import '../../domain/entities/flight_search.dart';
import 'flight_booking_page.dart';

class FlightDetailsPage extends StatefulWidget {
  const FlightDetailsPage({
    required this.offer,
    required this.search,
    super.key,
  });

  final FlightOffer offer;
  final FlightSearch search;

  @override
  State<FlightDetailsPage> createState() => _FlightDetailsPageState();
}

class _FlightDetailsPageState extends State<FlightDetailsPage> {
  final repository = ApiTravelSearchRepository();
  bool quoting = false;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  String _time(BuildContext context, DateTime? value) => value == null
      ? '--'
      : MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(value),
          alwaysUse24HourFormat: false,
        );

  String _duration(BuildContext context) {
    if (widget.offer.durationMinutes <= 0) {
      return context.tr('durationUnavailable');
    }
    final hours = widget.offer.durationMinutes ~/ 60;
    final minutes = widget.offer.durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _stops(BuildContext context) => widget.offer.stops == 0
      ? context.tr('direct')
      : '${widget.offer.stops} ${context.tr(widget.offer.stops == 1 ? 'stop' : 'stops')}';

  Future<void> _onBook() async {
    final app = AppControllerScope.of(context);
    if (app.isGuest) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.login_rounded, color: AppColors.teal, size: 28),
          title: Text(context.tr('signIn')),
          content: Text(context.tr('signInToBook')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr('signIn')),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => quoting = true);
    try {
      await repository.fareQuote(
        resultIndex: widget.offer.resultIndex ?? widget.offer.id,
        referenceIndex: widget.offer.referenceIndex,
        searchId: widget.offer.searchId ?? widget.search.searchId,
        supplier: widget.offer.supplier ?? 'tbo',
        currency: widget.offer.currency,
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      if (exception.isPriceConflict) {
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
                  ? '${exception.oldPrice} ${widget.offer.currency} -> ${exception.newPrice} ${widget.offer.currency}'
                  : exception.message,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('tryAgain')),
              ),
            ],
          ),
        );
      } else if (exception.isNotFound ||
          exception.isExpiredSession ||
          exception.isValidationError ||
          exception.statusCode == 500) {
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
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
      if (mounted) setState(() => quoting = false);
      return;
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$exception')));
      setState(() => quoting = false);
      return;
    }

    if (!mounted) return;
    setState(() => quoting = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FlightBookingPage(offer: widget.offer, search: widget.search),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final totalTravelers =
        widget.search.adults + widget.search.children + widget.search.infants;

    return Scaffold(
      bottomNavigationBar: _FlightDetailsFareBar(
        offer: widget.offer,
        search: widget.search,
        quoting: quoting,
        onBook: _onBook,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: isDark ? AppColors.navy : const Color(0xFFE8540B),
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _GlassCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: _GlassCircleButton(
                  icon: Icons.support_agent_rounded,
                  onTap: () => SaferBeSupportChatSheet.show(context),
                ),
              ),
            ],
            title: Text(
              context.tr('flightDetails'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _FlightHeroHeader(
                origin: widget.search.origin,
                destination: widget.search.destination,
                departureTime: _time(context, widget.offer.departureTime),
                arrivalTime: _time(context, widget.offer.arrivalTime),
                date: _date(context, widget.search.departure),
                airline: widget.offer.airline,
                cabinClass: widget.offer.cabinClass.isEmpty
                    ? _getCabinClassName(widget.search.cabinClass, isArabic)
                    : widget.offer.cabinClass,
                isDirect: widget.offer.stops == 0,
                duration: _duration(context),
                isArabic: isArabic,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Airline Info Banner Card
                  _AirlineBannerCard(
                    offer: widget.offer,
                    search: widget.search,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 18),

                  // Flight Timeline Breakdown
                  _FlightTimelineCard(
                    origin: widget.search.origin,
                    destination: widget.search.destination,
                    departureTime: _time(context, widget.offer.departureTime),
                    arrivalTime: _time(context, widget.offer.arrivalTime),
                    departureDate: _date(context, widget.search.departure),
                    arrivalDate: widget.search.returnDate != null
                        ? _date(context, widget.search.returnDate!)
                        : _date(context, widget.search.departure),
                    duration: _duration(context),
                    stops: _stops(context),
                    isDirect: widget.offer.stops == 0,
                    route: widget.offer.route,
                    airline: widget.offer.airline,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 18),

                  // 4-Item Flight Key Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _FlightMetricCard(
                          icon: Icons.calendar_month_rounded,
                          label: context.tr('departureMetric'),
                          value: _date(context, widget.search.departure),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FlightMetricCard(
                          icon: Icons.swap_horiz_rounded,
                          label: context.tr('journey'),
                          value: context.tr(
                            widget.search.returnDate == null
                                ? 'oneWay'
                                : 'return',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FlightMetricCard(
                          icon: Icons.people_alt_outlined,
                          label: context.tr('travelers'),
                          value:
                              '$totalTravelers ${context.tr(totalTravelers == 1 ? 'traveler' : 'travelers')}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FlightMetricCard(
                          icon: Icons.airline_seat_recline_extra_rounded,
                          label: context.tr('cabin'),
                          value: widget.offer.cabinClass.isEmpty
                              ? _getCabinClassName(
                                  widget.search.cabinClass,
                                  isArabic,
                                )
                              : widget.offer.cabinClass,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Inclusions & Baggage Allowance Section
                  _SectionHeader(
                    icon: Icons.luggage_outlined,
                    title: context.tr('flightInclusions'),
                  ),
                  const SizedBox(height: 10),
                  _BaggageInclusionCard(offer: widget.offer),
                  const SizedBox(height: 22),

                  // Fare Summary & Price Breakdown Section
                  _SectionHeader(
                    icon: Icons.receipt_long_rounded,
                    title: context.tr('priceBreakdown'),
                  ),
                  const SizedBox(height: 10),
                  _PriceBreakdownCard(
                    offer: widget.offer,
                    totalTravelers: totalTravelers,
                  ),
                  const SizedBox(height: 20),

                  // Trust Strip & Travel Guarantee
                  _TravelAssuranceCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightHeroHeader extends StatelessWidget {
  const _FlightHeroHeader({
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.date,
    required this.airline,
    required this.cabinClass,
    required this.isDirect,
    required this.duration,
    required this.isArabic,
  });

  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String date;
  final String airline;
  final String cabinClass;
  final bool isDirect;
  final String duration;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.navy,
              Color(0xFF092347),
              AppColors.navySoft,
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8540B),
              AppColors.orange,
              Color(0xFFFF7E22),
            ],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Origin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          origin,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          _getAirportCityName(origin, isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        if (departureTime != '--') ...[
                          const SizedBox(height: 2),
                          Text(
                            departureTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Flight route orb & duration
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            duration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: isArabic ? 3.14159 : 0,
                            child: Icon(
                              Icons.flight_takeoff_rounded,
                              color: isDark ? AppColors.teal : AppColors.orange,
                              size: 19,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isDirect
                              ? context.tr('direct')
                              : context.tr('connections'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Destination
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          _getAirportCityName(destination, isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        if (arrivalTime != '--') ...[
                          const SizedBox(height: 2),
                          Text(
                            arrivalTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bottom Glass Capsule (Date · Airline · Cabin)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CapsuleInfo(
                      icon: Icons.calendar_today_rounded,
                      text: date,
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _CapsuleInfo(
                      icon: Icons.flight_rounded,
                      text: airline,
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _CapsuleInfo(
                      icon: Icons.airline_seat_recline_normal_rounded,
                      text: cabinClass,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapsuleInfo extends StatelessWidget {
  const _CapsuleInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.white70),
      const SizedBox(width: 5),
      Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _AirlineBannerCard extends StatelessWidget {
  const _AirlineBannerCard({
    required this.offer,
    required this.search,
    required this.isArabic,
  });

  final FlightOffer offer;
  final FlightSearch search;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: AppColors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.airline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.cabinClass.isEmpty
                          ? _getCabinClassName(search.cabinClass, isArabic)
                          : offer.cabinClass,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _PolicyBadge(
                refundable: offer.refundable,
                label: context.tr(offer.refundable ? 'refundable' : 'nonRefundable'),
              ),
            ],
          ),
          if (offer.labels.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: offer.labels
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlightTimelineCard extends StatelessWidget {
  const _FlightTimelineCard({
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.duration,
    required this.stops,
    required this.isDirect,
    required this.route,
    required this.airline,
    required this.isArabic,
  });

  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final String duration;
  final String stops;
  final bool isDirect;
  final String route;
  final String airline;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
              const Icon(Icons.route_outlined, size: 20, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                context.tr('flightTimeline'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDirect ? AppColors.teal : AppColors.orange)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  stops,
                  style: TextStyle(
                    color: isDirect ? AppColors.teal : AppColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Departure Point
          _TimelineNode(
            time: departureTime,
            code: origin,
            city: _getAirportCityName(origin, isArabic),
            date: departureDate,
            isOrigin: true,
          ),

          // Flight Segment Interval
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 22),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: isArabic
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.teal, width: 2),
                  right: isArabic
                      ? const BorderSide(color: AppColors.teal, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 16,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$airline · $duration',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        if (route.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            route,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Arrival Point
          _TimelineNode(
            time: arrivalTime,
            code: destination,
            city: _getAirportCityName(destination, isArabic),
            date: arrivalDate,
            isOrigin: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.time,
    required this.code,
    required this.city,
    required this.date,
    required this.isOrigin,
  });

  final String time;
  final String code;
  final String city;
  final String date;
  final bool isOrigin;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: isOrigin ? AppColors.teal : AppColors.orange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: (isOrigin ? AppColors.teal : AppColors.orange)
                  .withValues(alpha: 0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$city · $date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FlightMetricCard extends StatelessWidget {
  const _FlightMetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.teal, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BaggageInclusionCard extends StatelessWidget {
  const _BaggageInclusionCard({required this.offer});
  final FlightOffer offer;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.luggage_rounded,
                color: AppColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.baggage.isNotEmpty
                        ? offer.baggage
                        : context.tr('baggageIncluded'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('baggageReview'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _InclusionPill(
              icon: Icons.backpack_outlined,
              label: context.tr('cabinBaggage'),
            ),
            _InclusionPill(
              icon: Icons.luggage_outlined,
              label: context.tr('checkedBaggage'),
            ),
            _InclusionPill(
              icon: Icons.verified_user_outlined,
              label: context.tr('noHiddenFees'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _InclusionPill extends StatelessWidget {
  const _InclusionPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.teal),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          color: AppColors.teal,
        ),
      ),
    ],
  );
}

class _PriceBreakdownCard extends StatelessWidget {
  const _PriceBreakdownCard({
    required this.offer,
    required this.totalTravelers,
  });

  final FlightOffer offer;
  final int totalTravelers;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
      ),
    ),
    child: Column(
      children: [
        _PriceRow(
          label: context.tr('baseFare'),
          value:
              '${(offer.price / (totalTravelers > 0 ? totalTravelers : 1)).toStringAsFixed(2)} ${offer.currency} × $totalTravelers',
        ),
        const SizedBox(height: 8),
        _PriceRow(
          label: context.tr('taxesAndFees'),
          value: context.tr('includedInPrice'),
          isPositive: true,
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('totalFare'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              '${offer.price.toStringAsFixed(2)} ${offer.currency}',
              style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isPositive = false,
  });

  final String label;
  final String value;
  final bool isPositive;

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
          color: isPositive ? AppColors.teal : null,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    ],
  );
}

class _TravelAssuranceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.teal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE6F7FA),
          foregroundColor: AppColors.teal,
          radius: 18,
          child: Icon(Icons.shield_outlined, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('secureCheckout'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('travelDocsInfo'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FlightDetailsFareBar extends StatelessWidget {
  const _FlightDetailsFareBar({
    required this.offer,
    required this.search,
    required this.quoting,
    required this.onBook,
  });

  final FlightOffer offer;
  final FlightSearch search;
  final bool quoting;
  final VoidCallback onBook;

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
              onPressed: quoting ? null : onBook,
              icon: quoting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.flight_takeoff_rounded, size: 20),
              label: Text(
                context.tr(quoting ? 'checkingFare' : 'selectFlight'),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.teal, size: 20),
      const SizedBox(width: 8),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _PolicyBadge extends StatelessWidget {
  const _PolicyBadge({required this.refundable, required this.label});
  final bool refundable;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = refundable ? AppColors.teal : AppColors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            refundable ? Icons.check_circle_rounded : Icons.info_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

String _getAirportCityName(String code, bool isAr) {
  final clean = code.trim().toUpperCase();
  const arMap = {
    'RUH': 'الرياض',
    'JED': 'جدة',
    'DMM': 'الدمام',
    'MED': 'المدينة المنورة',
    'AHB': 'أبها',
    'TIF': 'الطائف',
    'ELQ': 'القصيم',
    'GIZ': 'جازان',
    'HAS': 'حائل',
    'TUU': 'تبوك',
    'DXB': 'دبي',
    'AUH': 'أبوظبي',
    'DOH': 'الدوحة',
    'BAH': 'المنامة',
    'KWI': 'الكويت',
    'CAI': 'القاهرة',
    'HBE': 'الإسكندرية',
    'AMM': 'عمّان',
    'BEY': 'بيروت',
    'IST': 'إسطنبول',
    'SAW': 'إسطنبول صبيحة',
    'LHR': 'لندن',
    'LGW': 'لندن غاتويك',
    'CDG': 'باريس',
    'FRA': 'فرانكفورت',
    'MUC': 'ميونخ',
    'MXP': 'ميلانو',
    'FCO': 'روما',
    'VIE': 'فيينا',
    'BKK': 'بانكوك',
    'HKT': 'بوكيت',
    'KUL': 'كوالالمبور',
    'SIN': 'سنغافورة',
    'MLE': 'المالديف',
    'JFK': 'نيويورك',
    'LAX': 'لوس أنجلوس',
  };
  const enMap = {
    'RUH': 'Riyadh',
    'JED': 'Jeddah',
    'DMM': 'Dammam',
    'MED': 'Madinah',
    'AHB': 'Abha',
    'TIF': 'Taif',
    'ELQ': 'Qassim',
    'GIZ': 'Jazan',
    'HAS': 'Hail',
    'TUU': 'Tabuk',
    'DXB': 'Dubai',
    'AUH': 'Abu Dhabi',
    'DOH': 'Doha',
    'BAH': 'Manama',
    'KWI': 'Kuwait',
    'CAI': 'Cairo',
    'HBE': 'Alexandria',
    'AMM': 'Amman',
    'BEY': 'Beirut',
    'IST': 'Istanbul',
    'SAW': 'Istanbul SAW',
    'LHR': 'London',
    'LGW': 'London Gatwick',
    'CDG': 'Paris',
    'FRA': 'Frankfurt',
    'MUC': 'Munich',
    'MXP': 'Milan',
    'FCO': 'Rome',
    'VIE': 'Vienna',
    'BKK': 'Bangkok',
    'HKT': 'Phuket',
    'KUL': 'Kuala Lumpur',
    'SIN': 'Singapore',
    'MLE': 'Maldives',
    'JFK': 'New York',
    'LAX': 'Los Angeles',
  };
  return (isAr ? arMap[clean] : enMap[clean]) ?? clean;
}

String _getCabinClassName(int cabinClass, bool isAr) {
  switch (cabinClass) {
    case 1:
      return isAr ? 'السياحية' : 'Economy';
    case 2:
      return isAr ? 'سياحية مميزة' : 'Premium Economy';
    case 3:
      return isAr ? 'الأعمال' : 'Business';
    case 4:
      return isAr ? 'الأولى' : 'First';
    default:
      return isAr ? 'السياحية' : 'Economy';
  }
}
