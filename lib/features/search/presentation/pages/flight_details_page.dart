import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/flight_offer.dart';
import '../../domain/entities/flight_search.dart';
import 'flight_booking_page.dart';

class FlightDetailsPage extends StatelessWidget {
  const FlightDetailsPage({
    required this.offer,
    required this.search,
    super.key,
  });

  final FlightOffer offer;
  final FlightSearch search;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  String _time(BuildContext context, DateTime? value) => value == null
      ? '--'
      : MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(value),
          alwaysUse24HourFormat: false,
        );

  String _duration(BuildContext context) {
    if (offer.durationMinutes <= 0) return context.tr('durationUnavailable');
    final hours = offer.durationMinutes ~/ 60;
    final minutes = offer.durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _stops(BuildContext context) => offer.stops == 0
      ? context.tr('direct')
      : '${offer.stops} ${context.tr(offer.stops == 1 ? 'stop' : 'stops')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: _FareBar(offer: offer, search: search),
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          backgroundColor: AppColors.navySoft,
          foregroundColor: Colors.white,
          title: Text(context.tr('flightDetails')),
          flexibleSpace: FlexibleSpaceBar(
            background: _FlightHero(
              origin: search.origin,
              destination: search.destination,
              date: _date(context, search.departure),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE6F7FA),
                      foregroundColor: AppColors.teal,
                      child: Icon(Icons.flight_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.airline,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            offer.cabinClass.isEmpty
                                ? context.tr('flightOptionFallback')
                                : offer.cabinClass,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      icon: offer.refundable
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      label: context.tr(
                        offer.refundable ? 'refundable' : 'fareRules',
                      ),
                      color: offer.refundable
                          ? AppColors.teal
                          : AppColors.orange,
                    ),
                  ],
                ),
                if (offer.labels.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: offer.labels
                        .map((label) => _SmallChip(label: label))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                _TimelineCard(
                  origin: search.origin,
                  destination: search.destination,
                  departure: _time(context, offer.departureTime),
                  arrival: _time(context, offer.arrivalTime),
                  duration: _duration(context),
                  stops: _stops(context),
                  isDirect: offer.stops == 0,
                  route: offer.route,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _FlightMetric(
                        icon: Icons.calendar_month_rounded,
                        label: context.tr('departureMetric'),
                        value: _date(context, search.departure),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FlightMetric(
                        icon: Icons.swap_horiz_rounded,
                        label: context.tr('journey'),
                        value: context.tr(
                          search.returnDate == null ? 'oneWay' : 'return',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FlightMetric(
                        icon: Icons.people_outline,
                        label: context.tr('travelers'),
                        value:
                            '${search.adults + search.children + search.infants}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FlightMetric(
                        icon: Icons.airline_seat_recline_normal_rounded,
                        label: context.tr('cabin'),
                        value: offer.cabinClass.isEmpty
                            ? context.tr('selectedCabin')
                            : offer.cabinClass,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                  icon: Icons.luggage_outlined,
                  title: context.tr('baggage'),
                ),
                const SizedBox(height: 10),
                _InfoPanel(
                  icon: Icons.luggage_outlined,
                  title: offer.baggage.isEmpty
                      ? context.tr('baggageUnavailable')
                      : offer.baggage,
                  subtitle: context.tr('baggageReview'),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  icon: Icons.receipt_long_outlined,
                  title: context.tr('fareSummary'),
                ),
                const SizedBox(height: 10),
                _InfoPanel(
                  icon: Icons.payments_outlined,
                  title: '${offer.price.toStringAsFixed(2)} ${offer.currency}',
                  subtitle: offer.refundable
                      ? context.tr('refundableFare')
                      : context.tr('nonRefundableFare'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _FlightHero extends StatelessWidget {
  const _FlightHero({
    required this.origin,
    required this.destination,
    required this.date,
  });

  final String origin;
  final String destination;
  final String date;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navySoft, AppColors.teal],
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 78, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.flight_takeoff_rounded,
              color: Colors.white,
              size: 34,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _AirportCode(code: origin, label: context.tr('from')),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.east_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: _AirportCode(
                    code: destination,
                    label: context.tr('to'),
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              date,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AirportCode extends StatelessWidget {
  const _AirportCode({
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
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        code,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.stops,
    required this.isDirect,
    required this.route,
  });

  final String origin;
  final String destination;
  final String departure;
  final String arrival;
  final String duration;
  final String stops;
  final bool isDirect;
  final String route;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .35),
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            _TimeBlock(time: departure, code: origin),
            Expanded(
              child: Column(
                children: [
                  Text(
                    duration,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Divider(height: 1),
                  ),
                  Text(
                    stops,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDirect ? AppColors.teal : AppColors.orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            _TimeBlock(time: arrival, code: destination, alignEnd: true),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.route_outlined, size: 18, color: AppColors.muted),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                route,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.time,
    required this.code,
    this.alignEnd = false,
  });

  final String time;
  final String code;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 86,
    child: Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _FareBar extends StatefulWidget {
  const _FareBar({required this.offer, required this.search});

  final FlightOffer offer;
  final FlightSearch search;

  @override
  State<_FareBar> createState() => _FareBarState();
}

class _FareBarState extends State<_FareBar> {
  final repository = ApiTravelSearchRepository();
  bool quoting = false;

  Future<void> _onBook() async {
    final app = AppControllerScope.of(context);
    if (app.isGuest) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.login_rounded, color: AppColors.teal),
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
            icon: const Icon(Icons.event_busy_rounded, color: AppColors.orange),
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
                  context.tr('fare'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${widget.offer.price.toStringAsFixed(2)} ${widget.offer.currency}',
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
              onPressed: quoting ? null : _onBook,
              icon: quoting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.flight_rounded, size: 19),
              label: Text(
                context.tr(quoting ? 'checkingFare' : 'selectFlight'),
                style: TextStyle(fontWeight: FontWeight.w900),
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

class _FlightMetric extends StatelessWidget {
  const _FlightMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 78),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .35),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.teal, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .35),
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.orange.withValues(alpha: .1),
          foregroundColor: AppColors.orange,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
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

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.orange.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.orange,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
