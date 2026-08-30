import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../../core/widgets/travel_loading_view.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/hotel_offer.dart';
import '../../domain/entities/hotel_search.dart';
import '../widgets/hotel_filter_sheet.dart';
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
  HotelFilterState filterState = HotelFilterState();
  bool _loading = false;

  Future<List<HotelOffer>> reloadResults() async {
    setState(() {
      _loading = true;
    });
    final nextResults = repository.hotels(widget.search);
    setState(() {
      results = nextResults;
    });
    try {
      final res = await nextResults;
      return res;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void retry() {
    reloadResults();
  }

  Future<void> _openFilterSheet(List<HotelOffer> allOffers) async {
    final updated = await showModalBottomSheet<HotelFilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HotelFilterSheet(
        state: filterState,
        offers: allOffers,
      ),
    );
    if (updated != null) {
      setState(() => filterState = updated);
    }
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
            trailing: '${widget.search.adults} ${context.tr('adults')}',
            icon: Icons.bed_rounded,
          ),
        ),
      ),
    ),
    body: FutureBuilder<List<HotelOffer>>(
      future: results,
      builder: (context, snapshot) {
        if (_loading || snapshot.connectionState != ConnectionState.done) {
          return TravelLoadingView(
            icon: Icons.hotel_class_rounded,
            badge: widget.search.cityCode,
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
        final allOffers = snapshot.data ?? const [];
        if (allOffers.isEmpty) {
          return RequestStateView(
            icon: Icons.hotel_outlined,
            title: context.tr('noStaysFound'),
            message: context.tr('tryChangeDatesDestination'),
            actionLabel: context.tr('searchAgain'),
            onAction: () => Navigator.pop(context),
          );
        }

        final filteredOffers = filterState.apply(allOffers);

        return RefreshIndicator(
          onRefresh: reloadResults,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: filteredOffers.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 14 : 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HotelSummary(
                      search: widget.search,
                      count: filteredOffers.length,
                    ),
                    const SizedBox(height: 12),
                    _HotelQuickFilterStrip(
                      state: filterState,
                      onFilterTap: () => _openFilterSheet(allOffers),
                      onToggleFourPlus: () {
                        setState(() {
                          filterState.starFilter =
                              filterState.starFilter == HotelStarFilter.fourPlus
                              ? HotelStarFilter.any
                              : HotelStarFilter.fourPlus;
                        });
                      },
                      onToggleThreePlus: () {
                        setState(() {
                          filterState.starFilter =
                              filterState.starFilter == HotelStarFilter.threePlus
                              ? HotelStarFilter.any
                              : HotelStarFilter.threePlus;
                        });
                      },
                      onToggleCheapest: () {
                        setState(() {
                          filterState.sort =
                              filterState.sort == HotelSortMode.cheapest
                              ? HotelSortMode.best
                              : HotelSortMode.cheapest;
                        });
                      },
                      onToggleHighestRated: () {
                        setState(() {
                          filterState.sort =
                              filterState.sort == HotelSortMode.highestRated
                              ? HotelSortMode.best
                              : HotelSortMode.highestRated;
                        });
                      },
                      onReset: () => setState(() => filterState.reset()),
                    ),
                  ],
                );
              }
              final offer = filteredOffers[index - 1];
              return HotelOfferCard(
                offer: offer,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HotelDetailsPage(
                      offer: offer,
                      search: widget.search,
                    ),
                  ),
                ),
              );
            },
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

class _HotelQuickFilterStrip extends StatelessWidget {
  const _HotelQuickFilterStrip({
    required this.state,
    required this.onFilterTap,
    required this.onToggleFourPlus,
    required this.onToggleThreePlus,
    required this.onToggleCheapest,
    required this.onToggleHighestRated,
    required this.onReset,
  });

  final HotelFilterState state;
  final VoidCallback onFilterTap;
  final VoidCallback onToggleFourPlus;
  final VoidCallback onToggleThreePlus;
  final VoidCallback onToggleCheapest;
  final VoidCallback onToggleHighestRated;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        // Primary Filter button with active count
        ActionChip(
          onPressed: onFilterTap,
          avatar: Badge(
            isLabelVisible: state.isActive,
            label: Text('${state.activeCount}'),
            backgroundColor: AppColors.orange,
            child: const Icon(Icons.tune_rounded, size: 16),
          ),
          label: Text(
            state.isActive
                ? '${context.tr('filterStays')} (${state.activeCount})'
                : context.tr('filterStays'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          backgroundColor: state.isActive
              ? AppColors.teal.withValues(alpha: .15)
              : Theme.of(context).colorScheme.surface,
          side: BorderSide(
            color: state.isActive
                ? AppColors.teal
                : Theme.of(context).dividerColor.withValues(alpha: .35),
            width: state.isActive ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 8),
        _HotelQuickChip(
          icon: Icons.workspace_premium_rounded,
          label: '4★+ Premium',
          selected: state.starFilter == HotelStarFilter.fourPlus,
          onTap: onToggleFourPlus,
        ),
        const SizedBox(width: 8),
        _HotelQuickChip(
          icon: Icons.star_half_rounded,
          label: '3★+ Comfort',
          selected: state.starFilter == HotelStarFilter.threePlus,
          onTap: onToggleThreePlus,
        ),
        const SizedBox(width: 8),
        _HotelQuickChip(
          icon: Icons.savings_outlined,
          label: context.tr('cheapestFirst'),
          selected: state.sort == HotelSortMode.cheapest,
          onTap: onToggleCheapest,
        ),
        const SizedBox(width: 8),
        _HotelQuickChip(
          icon: Icons.star_rounded,
          label: context.tr('rating'),
          selected: state.sort == HotelSortMode.highestRated,
          onTap: onToggleHighestRated,
        ),
        if (state.isActive) ...[
          const SizedBox(width: 8),
          ActionChip(
            onPressed: onReset,
            avatar: const Icon(Icons.close_rounded, size: 15, color: AppColors.orange),
            label: Text(
              context.tr('resetAll'),
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            backgroundColor: AppColors.orange.withValues(alpha: .1),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ],
    ),
  );
}

class _HotelQuickChip extends StatelessWidget {
  const _HotelQuickChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
    avatar: Icon(
      icon,
      size: 15,
      color: selected ? AppColors.teal : AppColors.muted,
    ),
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.teal.withValues(alpha: .15),
    checkmarkColor: AppColors.teal,
    labelStyle: TextStyle(
      fontSize: 12,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      color: selected ? AppColors.teal : null,
    ),
    backgroundColor: Theme.of(context).colorScheme.surface,
    side: BorderSide(
      color: selected
          ? AppColors.teal
          : Theme.of(context).dividerColor.withValues(alpha: .35),
      width: selected ? 1.5 : 1,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
