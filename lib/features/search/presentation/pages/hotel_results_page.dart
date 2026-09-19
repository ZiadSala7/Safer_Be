import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../../core/widgets/travel_loading_view.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/hotel_offer.dart';
import '../../domain/entities/hotel_search.dart';
import '../widgets/currency_picker_sheet.dart';
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
  late HotelSearch _currentSearch = widget.search;
  late Future<List<HotelOffer>> results = repository.hotels(_currentSearch);
  HotelFilterState filterState = HotelFilterState();
  bool _loading = false;

  Future<List<HotelOffer>> reloadResults() async {
    setState(() {
      _loading = true;
    });
    final nextResults = repository.hotels(_currentSearch);
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

  void _onCurrencyChanged(String newCurrency) {
    final normalized = newCurrency.trim().toUpperCase();
    if (normalized.isEmpty || _currentSearch.currency == normalized) return;
    setState(() {
      _currentSearch = _currentSearch.copyWith(currency: normalized);
    });
    try {
      AppControllerScope.of(context).setCurrency(normalized);
    } catch (_) {}
    reloadResults();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.teal : AppColors.orange;

    return Scaffold(
      appBar: _HotelResultsHeaderAppBar(
        search: _currentSearch,
        activeFilters: filterState,
        onRetry: retry,
        onCurrencyChanged: _onCurrencyChanged,
        onOpenFilters: () async {
          final res = await results;
          if (mounted) _openFilterSheet(res);
        },
      ),
      body: FutureBuilder<List<HotelOffer>>(
        future: results,
        builder: (context, snapshot) {
          if (_loading || snapshot.connectionState != ConnectionState.done) {
            return TravelLoadingView(
              icon: Icons.hotel_class_rounded,
              badge: _currentSearch.cityCode,
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
              accentColor: accentColor,
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
              accentColor: accentColor,
              onAction: () => Navigator.pop(context),
            );
          }

          final filteredOffers = filterState.apply(allOffers);
          if (filteredOffers.isEmpty) {
            return RequestStateView(
              icon: Icons.filter_alt_off_rounded,
              title: context.tr('noStaysFound'),
              message: context.tr('tryChangeDatesDestination'),
              actionLabel: context.tr('resetAll'),
              accentColor: accentColor,
              onAction: () => setState(() => filterState.reset()),
            );
          }

          return RefreshIndicator(
            onRefresh: reloadResults,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: filteredOffers.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 12 : 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HotelResultsBanner(
                        search: _currentSearch,
                        count: filteredOffers.length,
                        totalCount: allOffers.length,
                        filters: filterState,
                      ),
                      const SizedBox(height: 12),
                      _HotelQuickFilterStrip(
                        state: filterState,
                        currentCurrency: _currentSearch.currency,
                        onCurrencyTap: () => showCurrencyPickerSheet(
                          context,
                          currentCurrency: _currentSearch.currency,
                          onSelected: _onCurrencyChanged,
                        ),
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
                        search: _currentSearch,
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
}

class _HotelResultsHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HotelResultsHeaderAppBar({
    required this.search,
    required this.activeFilters,
    required this.onRetry,
    required this.onOpenFilters,
    required this.onCurrencyChanged,
  });

  final HotelSearch search;
  final HotelFilterState activeFilters;
  final VoidCallback onRetry;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Size get preferredSize => const Size.fromHeight(214);

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  String _guestCount(BuildContext context, int adults, int children) {
    final total = adults + children;
    return '$total ${context.tr(total == 1 ? 'adult' : 'adults')}';
  }

  String _roomCount(BuildContext context, int rooms) =>
      '$rooms ${context.tr(rooms == 1 ? 'rooms' : 'rooms')}';

  String _formatDateSpan(BuildContext context, HotelSearch s) {
    final d1 = _date(context, s.checkIn);
    final d2 = _date(context, s.checkOut);
    return '$d1 - $d2';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final nights = search.checkOut.difference(search.checkIn).inDays;

    final headerGradient = isDark
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

    final shadowColor = isDark
        ? AppColors.navy.withValues(alpha: 0.35)
        : AppColors.orange.withValues(alpha: 0.32);

    final cityColor = isDark
        ? AppColors.tealLight
        : const Color(0xFFFFE5D0);

    final stayPillBg = isDark
        ? AppColors.teal.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.22);

    final stayPillBorder = isDark
        ? AppColors.tealLight.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.45);

    final stayTextColor = isDark
        ? const Color(0xFF67E8F9)
        : Colors.white;

    final hotelOrbGradient = isDark
        ? const LinearGradient(
            colors: [AppColors.teal, AppColors.tealLight],
          )
        : const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF3E0)],
          );

    final hotelIconColor = isDark
        ? Colors.white
        : AppColors.orange;

    final hotelOrbShadow = isDark
        ? AppColors.teal.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.22);

    final chipIconColor = isDark
        ? AppColors.tealLight
        : const Color(0xFFFFE0B2);

    final badgeColor = isDark
        ? AppColors.orange
        : AppColors.navy;

    return Container(
      decoration: BoxDecoration(
        gradient: headerGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Nav Bar
              Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 6),
                  // Glowing Live Title Pill (Auto-adapting & overflow-safe)
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final showText = constraints.maxWidth >= 55;
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: showText ? 9 : 7,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF10B981) : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? const Color(0xFF10B981)
                                            : Colors.white.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 1.5,
                                      ),
                                    ],
                                  ),
                                ),
                                if (showText) ...[
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      context.tr('availableStays'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Actions (Currency, Refresh & Filter)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassCurrencyPickerButton(
                        currency: search.currency,
                        onSelected: onCurrencyChanged,
                        compact: true,
                      ),
                      const SizedBox(width: 5),
                      _GlassIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: context.tr('refreshStays'),
                        onTap: onRetry,
                      ),
                      const SizedBox(width: 5),
                      _GlassIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: context.tr('filterStays'),
                        badgeCount: activeFilters.activeCount,
                        badgeColor: badgeColor,
                        onTap: onOpenFilters,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Destination & Stay Showcase
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Destination City Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          search.cityCode.isEmpty ? 'HOTEL' : search.cityCode,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: 1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getCityName(search.cityCode, isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cityColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Nights Orb & Label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: stayPillBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: stayPillBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '$nights ${context.tr(nights == 1 ? 'night' : 'nights')}',
                            style: TextStyle(
                              color: stayTextColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: hotelOrbGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: hotelOrbShadow,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.hotel_rounded,
                            color: hotelIconColor,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dates Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDateSpan(context, search),
                          maxLines: 1,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.4,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr('liveAvailabilityDates'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cityColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Specifications Glass Capsule (Dates · Guests · Rooms)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.24),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _HeaderTripChip(
                        icon: Icons.calendar_month_rounded,
                        iconColor: chipIconColor,
                        label: _formatDateSpan(context, search),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    Expanded(
                      child: _HeaderTripChip(
                        icon: Icons.people_alt_outlined,
                        iconColor: chipIconColor,
                        label: _guestCount(context, search.adults, search.children),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    Expanded(
                      child: _HeaderTripChip(
                        icon: Icons.meeting_room_outlined,
                        iconColor: chipIconColor,
                        label: _roomCount(context, search.rooms),
                      ),
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

class _HotelResultsBanner extends StatelessWidget {
  const _HotelResultsBanner({
    required this.search,
    required this.count,
    required this.totalCount,
    required this.filters,
  });

  final HotelSearch search;
  final int count;
  final int totalCount;
  final HotelFilterState filters;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final accentColor = isDark ? AppColors.teal : AppColors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_outlined,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      '$count ${context.tr(count == 1 ? 'stayFound' : 'staysFound')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    if (filters.isActive)
                      Text(
                        '(${context.tr('filterStays')}: $totalCount)',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'مقارنة أسعار إقامة مباشرة بدون رسوم إضافية'
                      : 'Direct stay rate comparison · No hidden fees',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badgeCount = 0,
    this.badgeColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int badgeCount;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );

    if (badgeCount > 0) {
      button = Badge(
        label: Text(
          '$badgeCount',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
        ),
        backgroundColor: badgeColor ?? AppColors.orange,
        textColor: Colors.white,
        child: button,
      );
    }

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _HeaderTripChip extends StatelessWidget {
  const _HeaderTripChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 13, color: iconColor ?? AppColors.tealLight),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _HotelQuickFilterStrip extends StatelessWidget {
  const _HotelQuickFilterStrip({
    required this.state,
    required this.currentCurrency,
    required this.onCurrencyTap,
    required this.onFilterTap,
    required this.onToggleFourPlus,
    required this.onToggleThreePlus,
    required this.onToggleCheapest,
    required this.onToggleHighestRated,
    required this.onReset,
  });

  final HotelFilterState state;
  final String currentCurrency;
  final VoidCallback onCurrencyTap;
  final VoidCallback onFilterTap;
  final VoidCallback onToggleFourPlus;
  final VoidCallback onToggleThreePlus;
  final VoidCallback onToggleCheapest;
  final VoidCallback onToggleHighestRated;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.teal : AppColors.orange;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Currency Selector Quick Chip
          ActionChip(
            onPressed: onCurrencyTap,
            avatar: const Icon(
              Icons.currency_exchange_rounded,
              size: 16,
              color: AppColors.orange,
            ),
            label: Text(
              '$currentCurrency ▾',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: .35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 8),

          // Primary Filter button with active count
          ActionChip(
            onPressed: onFilterTap,
            avatar: Badge(
              isLabelVisible: state.isActive,
              label: Text('${state.activeCount}'),
              backgroundColor: isDark ? AppColors.orange : AppColors.navy,
              child: const Icon(Icons.tune_rounded, size: 16),
            ),
            label: Text(
              state.isActive
                  ? '${context.tr('filterStays')} (${state.activeCount})'
                  : context.tr('filterStays'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            backgroundColor: state.isActive
                ? activeColor.withValues(alpha: .15)
                : Theme.of(context).colorScheme.surface,
            side: BorderSide(
              color: state.isActive
                  ? activeColor
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.teal : AppColors.orange;

    return FilterChip(
      avatar: Icon(
        icon,
        size: 15,
        color: selected ? activeColor : AppColors.muted,
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: activeColor.withValues(alpha: .15),
      checkmarkColor: activeColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected ? activeColor : null,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: selected
            ? activeColor
            : Theme.of(context).dividerColor.withValues(alpha: .35),
        width: selected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

String _getCityName(String code, bool isAr) {
  final upper = code.trim().toUpperCase();
  switch (upper) {
    case 'RUH':
      return isAr ? 'الرياض' : 'Riyadh';
    case 'JED':
      return isAr ? 'جدة' : 'Jeddah';
    case 'DMM':
      return isAr ? 'الدمام' : 'Dammam';
    case 'MED':
      return isAr ? 'المدينة المنورة' : 'Medina';
    case 'AHB':
      return isAr ? 'أبها' : 'Abha';
    case 'TIF':
      return isAr ? 'الطائف' : 'Taif';
    case 'DXB':
      return isAr ? 'دبي' : 'Dubai';
    case 'AUH':
      return isAr ? 'أبوظبي' : 'Abu Dhabi';
    case 'DOH':
      return isAr ? 'الدوحة' : 'Doha';
    case 'KWI':
      return isAr ? 'الكويت' : 'Kuwait';
    case 'BAH':
      return isAr ? 'المنامة' : 'Manama';
    case 'MCT':
      return isAr ? 'مسقط' : 'Muscat';
    case 'CAI':
      return isAr ? 'القاهرة' : 'Cairo';
    case 'ALX':
    case 'HBE':
      return isAr ? 'الإسكندرية' : 'Alexandria';
    case 'SSH':
      return isAr ? 'شرم الشيخ' : 'Sharm El Sheikh';
    case 'HRG':
      return isAr ? 'الغردقة' : 'Hurghada';
    case 'AMM':
      return isAr ? 'عمان' : 'Amman';
    case 'BEY':
      return isAr ? 'بيروت' : 'Beirut';
    case 'IST':
    case 'SAW':
      return isAr ? 'إسطنبول' : 'Istanbul';
    case 'AYT':
      return isAr ? 'أنطاليا' : 'Antalya';
    case 'LON':
    case 'LHR':
    case 'LGW':
      return isAr ? 'لندن' : 'London';
    case 'PAR':
    case 'CDG':
    case 'ORY':
      return isAr ? 'باريس' : 'Paris';
    case 'ROM':
    case 'FCO':
      return isAr ? 'روما' : 'Rome';
    case 'MAD':
      return isAr ? 'مدريد' : 'Madrid';
    case 'BCN':
      return isAr ? 'برشلونة' : 'Barcelona';
    case 'VIE':
      return isAr ? 'فيينا' : 'Vienna';
    case 'AMS':
      return isAr ? 'أمستردام' : 'Amsterdam';
    case 'FRA':
      return isAr ? 'فرانكفورت' : 'Frankfurt';
    case 'MUC':
      return isAr ? 'ميونخ' : 'Munich';
    case 'BKK':
    case 'DMK':
      return isAr ? 'بانكوك' : 'Bangkok';
    case 'HKT':
      return isAr ? 'بوكيت' : 'Phuket';
    case 'KUL':
      return isAr ? 'كوالالمبور' : 'Kuala Lumpur';
    case 'SIN':
      return isAr ? 'سنغافورة' : 'Singapore';
    case 'DPS':
      return isAr ? 'بالي' : 'Bali';
    case 'MLE':
      return isAr ? 'المالديف' : 'Maldives';
    case 'TBS':
      return isAr ? 'تبليسي' : 'Tbilisi';
    case 'GYD':
      return isAr ? 'باكو' : 'Baku';
    case 'EVN':
      return isAr ? 'يريفان' : 'Yerevan';
    case 'SEZ':
      return isAr ? 'سيشل' : 'Seychelles';
    default:
      return upper;
  }
}
