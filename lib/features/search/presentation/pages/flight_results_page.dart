import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../../core/widgets/travel_loading_view.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/flight_offer.dart';
import '../../domain/entities/flight_search.dart';
import '../../domain/entities/flight_search_response.dart';
import '../widgets/flight_filter_sheet.dart';
import '../widgets/flight_offer_card.dart';
import 'flight_details_page.dart';

class FlightResultsPage extends StatefulWidget {
  const FlightResultsPage({required this.search, super.key});
  final FlightSearch search;

  @override
  State<FlightResultsPage> createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage> {
  final repository = ApiTravelSearchRepository();
  late FlightSearch _activeSearch = widget.search;
  late Future<FlightSearchResponse> results = repository.searchFlights(
    _activeSearch,
  );
  FlightFilterState filters = FlightFilterState();

  Future<FlightSearchResponse> reloadResults() {
    final nextResults = repository.searchFlights(_activeSearch);
    setState(() {
      results = nextResults;
    });
    return nextResults;
  }

  void retry() {
    reloadResults();
  }

  Future<void> openFilters(List<FlightOffer> offers) async {
    final selected = await FlightFilterSheet.show(
      context,
      state: filters,
      allOffers: offers,
    );
    if (selected == null) return;

    final oldAirlines = filters.airlines.join(',');
    final newAirlines = selected.airlines.join(',');
    setState(() => filters = selected);

    if (oldAirlines != newAirlines) {
      _activeSearch = widget.search.copyWith(
        preferredAirlines: selected.airlines.toList(),
        filters: selected.airlines.isEmpty
            ? null
            : FlightSearchFilters(airlines: selected.airlines.toList()),
        clearFilters: selected.airlines.isEmpty,
        clearSearchId: true,
      );
      reloadResults();
    }
  }

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  String _travelerCount(BuildContext context, int count) =>
      '$count ${context.tr(count == 1 ? 'adult' : 'adults')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: _ResultTitle(
        title: context.tr('availableFlights'),
        subtitle: context.tr('liveFaresSchedules'),
        icon: Icons.flight_takeoff_rounded,
      ),
      actions: [
        IconButton(
          tooltip: context.tr('refreshFlights'),
          onPressed: retry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _TripStrip(
            leading:
                '${widget.search.origin} ${context.tr('to')} ${widget.search.destination}',
            middle: _date(context, widget.search.departure),
            trailing: _travelerCount(context, widget.search.adults),
            icon: Icons.route_rounded,
          ),
        ),
      ),
    ),
    body: FutureBuilder<FlightSearchResponse>(
      future: results,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return TravelLoadingView(
            icon: Icons.flight_takeoff_rounded,
            title: context.tr('loadingFlights'),
            steps: [
              context.tr('loadingFlightsStep1'),
              context.tr('loadingFlightsStep2'),
              context.tr('loadingFlightsStep3'),
            ],
          );
        }
        if (snapshot.hasError) {
          return RequestStateView(
            icon: Icons.cloud_off_rounded,
            title: context.tr('couldNotLoadFlights'),
            message: '${snapshot.error}',
            actionLabel: context.tr('tryAgain'),
            onAction: retry,
          );
        }
        final response = snapshot.data ?? FlightSearchResponse.empty;
        final offers = response.offers;
        final visibleOffers = filters.apply(offers);
        if (offers.isEmpty) {
          return RequestStateView(
            icon: Icons.flight_takeoff_rounded,
            title: context.tr('noFlightsFound'),
            message: context.tr('tryAnotherDateAirport'),
            actionLabel: context.tr('searchAgain'),
            onAction: () => Navigator.pop(context),
          );
        }
        if (visibleOffers.isEmpty) {
          return RequestStateView(
            icon: Icons.filter_alt_off_rounded,
            title: context.tr('noFlightsFound'),
            message: context.tr('tryAnotherDateAirport'),
            actionLabel: context.tr('resetFilters'),
            onAction: () => setState(() => filters.reset()),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await reloadResults();
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: visibleOffers.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 14 : 12),
            itemBuilder: (context, index) => index == 0
                ? _SearchSummary(
                    search: _activeSearch,
                    count: visibleOffers.length,
                    totalCount: offers.length,
                    filters: filters,
                    searchId: response.searchId,
                    onFilter: () => openFilters(offers),
                  )
                : FlightOfferCard(
                    offer: visibleOffers[index - 1],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlightDetailsPage(
                          offer: visibleOffers[index - 1].copyWith(
                            searchId: response.searchId,
                            supplier:
                                visibleOffers[index - 1].supplier ??
                                response.supplier,
                          ),
                          search: _activeSearch.copyWith(
                            searchId: response.searchId,
                          ),
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

class _SearchSummary extends StatelessWidget {
  const _SearchSummary({
    required this.search,
    required this.count,
    required this.totalCount,
    required this.filters,
    required this.onFilter,
    this.searchId,
  });
  final FlightSearch search;
  final int count;
  final int totalCount;
  final FlightFilterState filters;
  final VoidCallback onFilter;
  final String? searchId;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  @override
  Widget build(BuildContext context) {
    final totalTravelers = search.adults + search.children + search.infants;
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
                child: const Icon(Icons.flight_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$count ${context.tr(count == 1 ? 'flightOption' : 'flightOptions')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (filters.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$count/$totalCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${search.origin} ${context.tr('to')} ${search.destination}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: context.tr('filtersTitle'),
                onPressed: onFilter,
                icon: Badge.count(
                  count: filters.activeCount,
                  isLabelVisible: filters.activeCount > 0,
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: context.tr('departureMetric'),
                  value: _date(context, search.departure),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  label: context.tr('journey'),
                  value: context.tr(
                    search.returnDate == null ? 'oneWay' : 'return',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  label: context.tr('travelers'),
                  value: '$totalTravelers',
                ),
              ),
            ],
          ),
          if (searchId != null && searchId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${context.tr('searchReference')}: $searchId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
            leading,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            middle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
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
