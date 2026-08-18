import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../../core/widgets/travel_loading_view.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/hotel_offer.dart';
import '../../domain/entities/hotel_search.dart';
import '../widgets/hotel_offer_card.dart';
import 'hotel_details_page.dart';

class HotelResultsPage extends StatefulWidget {
  const HotelResultsPage({required this.search, super.key});
  final HotelSearch search;

  @override
  State<HotelResultsPage> createState() => _HotelResultsPageState();
}

class _HotelResultsPageState extends State<HotelResultsPage> {
  final repository = ApiTravelSearchRepository();
  late Future<List<HotelOffer>> results = repository.hotels(widget.search);

  Future<List<HotelOffer>> reloadResults() {
    final nextResults = repository.hotels(widget.search);
    setState(() {
      results = nextResults;
    });
    return nextResults;
  }

  void retry() {
    reloadResults();
  }

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: _ResultTitle(
        title: context.tr('availableStays'),
        subtitle: context.tr('liveHotelAvailability'),
        icon: Icons.hotel_rounded,
      ),
      actions: [
        IconButton(
          tooltip: context.tr('refreshStays'),
          onPressed: retry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _TripStrip(
            leading: widget.search.cityCode,
            middle:
                '${_date(context, widget.search.checkIn)} - ${_date(context, widget.search.checkOut)}',
            trailing: '2 ${context.tr('adults')}',
            icon: Icons.bed_rounded,
          ),
        ),
      ),
    ),
    body: FutureBuilder<List<HotelOffer>>(
      future: results,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return TravelLoadingView(
            icon: Icons.hotel_class_rounded,
            title: context.tr('loadingHotels'),
            steps: [
              context.tr('loadingHotelsStep1'),
              context.tr('loadingHotelsStep2'),
              context.tr('loadingHotelsStep3'),
            ],
          );
        }
        if (snapshot.hasError) {
          return RequestStateView(
            icon: Icons.cloud_off_rounded,
            title: context.tr('couldNotLoadHotels'),
            message: '${snapshot.error}',
            actionLabel: context.tr('tryAgain'),
            onAction: retry,
          );
        }
        final offers = snapshot.data ?? const [];
        if (offers.isEmpty) {
          return RequestStateView(
            icon: Icons.hotel_outlined,
            title: context.tr('noStaysFound'),
            message: context.tr('tryChangeDatesDestination'),
            actionLabel: context.tr('searchAgain'),
            onAction: () => Navigator.pop(context),
          );
        }
        return RefreshIndicator(
          onRefresh: reloadResults,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: offers.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 14 : 12),
            itemBuilder: (context, index) => index == 0
                ? _HotelSummary(search: widget.search, count: offers.length)
                : HotelOfferCard(
                    offer: offers[index - 1],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelDetailsPage(
                          offer: offers[index - 1],
                          search: widget.search,
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    ),
  );
}

class _ResultTitle extends StatelessWidget {
  const _ResultTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.teal, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _TripStrip extends StatelessWidget {
  const _TripStrip({
    required this.leading,
    required this.middle,
    required this.trailing,
    required this.icon,
  });

  final String leading;
  final String middle;
  final String trailing;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .35),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            leading.isEmpty ? context.tr('destination') : leading,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          middle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HotelSummary extends StatelessWidget {
  const _HotelSummary({required this.search, required this.count});
  final HotelSearch search;
  final int count;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  @override
  Widget build(BuildContext context) {
    final nights = search.checkOut.difference(search.checkIn).inDays;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navySoft, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bed_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count ${context.tr(count == 1 ? 'stayFound' : 'staysFound')}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr('liveAvailabilityDates'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: context.tr('checkInLabel'),
                  value: _date(context, search.checkIn),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  label: context.tr('checkOutLabel'),
                  value: _date(context, search.checkOut),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  label: context.tr('stay'),
                  value:
                      '$nights ${context.tr(nights == 1 ? 'night' : 'nights')}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 58),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
