import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../../core/widgets/travel_loading_view.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/flight_offer.dart';
import '../../domain/entities/flight_search.dart';
import '../../domain/entities/flight_search_response.dart';
import '../../domain/utils/travel_search_engine.dart';
import '../widgets/ai_travel_search_bar.dart';
import '../widgets/currency_picker_sheet.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late FlightSearch _activeSearch = widget.search;
  late Future<FlightSearchResponse> results = repository.searchFlights(
    _activeSearch,
  );
  FlightFilterState filters = FlightFilterState();
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AiSearchPromptChip> _getFlightPrompts(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return [
      AiSearchPromptChip(
        icon: Icons.auto_awesome_rounded,
        label: context.tr('aiPromptCheapestFlights'),
        query: isArabic ? 'أرخص الرحلات المباشرة' : 'Cheapest direct flights',
      ),
      AiSearchPromptChip(
        icon: Icons.flight_takeoff_rounded,
        label: context.tr('aiPromptDirectFlights'),
        query: isArabic ? 'رحلات مباشرة' : 'Direct flights',
      ),
      AiSearchPromptChip(
        icon: Icons.luggage_rounded,
        label: context.tr('aiPromptWithBaggage'),
        query: isArabic ? 'شامل الأمتعة' : 'With baggage',
      ),
      AiSearchPromptChip(
        icon: Icons.airlines_rounded,
        label: context.tr('aiPromptFlynas'),
        query: isArabic ? 'طيران ناس' : 'flynas',
      ),
      AiSearchPromptChip(
        icon: Icons.airlines_rounded,
        label: context.tr('aiPromptSaudia'),
        query: isArabic ? 'الخطوط السعودية' : 'Saudia',
      ),
      AiSearchPromptChip(
        icon: Icons.wb_sunny_outlined,
        label: context.tr('aiPromptMorningFlights'),
        query: isArabic ? 'رحلات صباحية' : 'Morning flights',
      ),
      AiSearchPromptChip(
        icon: Icons.nightlight_round_outlined,
        label: context.tr('aiPromptEveningFlights'),
        query: isArabic ? 'رحلات مسائية' : 'Evening flights',
      ),
      AiSearchPromptChip(
        icon: Icons.price_check_rounded,
        label: context.tr('aiPromptUnder500'),
        query: isArabic ? 'أقل من 500' : 'Under 500',
      ),
      AiSearchPromptChip(
        icon: Icons.verified_user_outlined,
        label: context.tr('aiPromptRefundable'),
        query: isArabic ? 'تذاكر قابلة للاسترداد' : 'Refundable',
      ),
    ];
  }

  Future<FlightSearchResponse> reloadResults() async {
    setState(() {
      _loading = true;
    });
    final nextResults = repository.searchFlights(_activeSearch);
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
    if (normalized.isEmpty || _activeSearch.currency == normalized) return;
    setState(() {
      _activeSearch = _activeSearch.copyWith(
        currency: normalized,
        clearSearchId: true,
      );
    });
    try {
      AppControllerScope.of(context).setCurrency(normalized);
    } catch (_) {}
    reloadResults();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _FlightResultsHeaderAppBar(
      search: _activeSearch,
      activeFilters: filters,
      onRetry: retry,
      onCurrencyChanged: _onCurrencyChanged,
      onOpenFilters: () async {
        final res = await results;
        if (mounted) openFilters(res.offers);
      },
    ),
    body: FutureBuilder<FlightSearchResponse>(
      future: results,
      builder: (context, snapshot) {
        if (_loading || snapshot.connectionState != ConnectionState.done) {
          return TravelLoadingView(
            icon: Icons.flight_takeoff_rounded,
            badge: '${_activeSearch.origin} → ${_activeSearch.destination}',
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
        final visibleOffers = TravelSearchEngine.filterFlights(
          offers: offers,
          filters: filters,
          query: _searchQuery,
        );
        if (offers.isEmpty) {
          return RequestStateView(
            icon: Icons.flight_takeoff_rounded,
            title: context.tr('noFlightsFound'),
            message: context.tr('tryAnotherDateAirport'),
            actionLabel: context.tr('searchAgain'),
            onAction: () => Navigator.pop(context),
          );
        }

        final hasMatches = visibleOffers.isNotEmpty;
        final prompts = _getFlightPrompts(context);

        return RefreshIndicator(
          onRefresh: () async {
            await reloadResults();
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: hasMatches ? visibleOffers.length + 1 : 2,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 12 : 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FlightResultsBanner(
                      count: visibleOffers.length,
                      totalCount: offers.length,
                      searchId: response.searchId,
                      filters: filters,
                    ),
                    const SizedBox(height: 10),
                    _QuickFilterStrip(
                      state: filters,
                      currentCurrency: _activeSearch.currency,
                      onCurrencyTap: () => showCurrencyPickerSheet(
                        context,
                        currentCurrency: _activeSearch.currency,
                        onSelected: _onCurrencyChanged,
                      ),
                      onFilterTap: () => openFilters(offers),
                      onToggleDirect: () {
                        setState(() {
                          filters.stops = filters.stops == FlightStopsMode.direct
                              ? FlightStopsMode.any
                              : FlightStopsMode.direct;
                        });
                      },
                      onToggleBaggage: () {
                        setState(() {
                          filters.includesCheckedBaggage =
                              !filters.includesCheckedBaggage;
                        });
                      },
                      onToggleRefundable: () {
                        setState(() {
                          filters.refundableOnly = !filters.refundableOnly;
                        });
                      },
                      onToggleCheapest: () {
                        setState(() {
                          filters.sort =
                              filters.sort == FlightSortMode.cheapest
                              ? FlightSortMode.best
                              : FlightSortMode.cheapest;
                        });
                      },
                      onToggleShortest: () {
                        setState(() {
                          filters.sort =
                              filters.sort == FlightSortMode.shortest
                              ? FlightSortMode.best
                              : FlightSortMode.shortest;
                        });
                      },
                      onReset: () {
                        setState(() {
                          filters.reset();
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    AiTravelSearchBar(
                      controller: _searchController,
                      placeholderKey: 'aiSearchPlaceholderFlights',
                      prompts: prompts,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                );
              }

              if (!hasMatches) {
                return AiSearchEmptyState(
                  title: context.tr('noMatchingFlightsFound'),
                  message: context.tr('tryDifferentKeywords'),
                  onClear: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      filters.reset();
                    });
                  },
                );
              }

              final offer = visibleOffers[index - 1];
              return FlightOfferCard(
                offer: offer,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlightDetailsPage(
                      offer: offer.copyWith(
                        searchId: response.searchId,
                        supplier: offer.supplier ?? response.supplier,
                      ),
                      search: _activeSearch.copyWith(
                        searchId: response.searchId,
                      ),
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

class _FlightResultsHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FlightResultsHeaderAppBar({
    required this.search,
    required this.activeFilters,
    required this.onRetry,
    required this.onOpenFilters,
    required this.onCurrencyChanged,
  });

  final FlightSearch search;
  final FlightFilterState activeFilters;
  final VoidCallback onRetry;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Size get preferredSize => const Size.fromHeight(214);

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  String _travelerCount(BuildContext context, int count) =>
      '$count ${context.tr(count == 1 ? 'adult' : 'adults')}';

  String _formatDateSpan(BuildContext context, FlightSearch s) {
    final d1 = _date(context, s.departure);
    if (s.returnDate != null) {
      final d2 = _date(context, s.returnDate!);
      return '$d1 - $d2';
    }
    return d1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final totalTravelers = search.adults + search.children + search.infants;

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

    final tripTypeBg = isDark
        ? AppColors.teal.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.22);

    final tripTypeBorder = isDark
        ? AppColors.tealLight.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.45);

    final tripTypeTextColor = isDark
        ? const Color(0xFF67E8F9)
        : Colors.white;

    final airplaneOrbGradient = isDark
        ? const LinearGradient(
            colors: [AppColors.teal, AppColors.tealLight],
          )
        : const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF3E0)],
          );

    final airplaneIconColor = isDark
        ? Colors.white
        : AppColors.orange;

    final airplaneOrbShadow = isDark
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
              // Top Nav Bar (Back button, Title Pill, Action Buttons)
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
                                      context.tr('availableFlights'),
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
                        tooltip: context.tr('refreshFlights'),
                        onTap: onRetry,
                      ),
                      const SizedBox(width: 5),
                      _GlassIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: context.tr('filtersTitle'),
                        badgeCount: activeFilters.activeCount,
                        badgeColor: badgeColor,
                        onTap: onOpenFilters,
                      ),
                    ],
                  ),
                ],
              ),
                  const SizedBox(height: 14),

                  // Route Visual Showcase (Origin ✈️ Destination)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Origin Airport
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              search.origin,
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
                              _getAirportCityName(search.origin, isArabic),
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

                      // Center Flight Route Trail & Trip Type
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: tripTypeBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tripTypeBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _getTripTypeLabel(search, isArabic),
                                style: TextStyle(
                                  color: tripTypeTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 96,
                              height: 28,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(96, 12),
                                    painter: _FlightTrailPainter(),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      gradient: airplaneOrbGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: airplaneOrbShadow,
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Transform.rotate(
                                      angle: isArabic ? 3.14159 : 0,
                                      child: Icon(
                                        Icons.flight_takeoff_rounded,
                                        color: airplaneIconColor,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Destination Airport
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              search.destination,
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
                              _getAirportCityName(search.destination, isArabic),
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
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Specifications Glass Capsule (Date · Travelers · Cabin)
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
                            icon: Icons.calendar_today_rounded,
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
                            label: _travelerCount(context, totalTravelers),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 14,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        Expanded(
                          child: _HeaderTripChip(
                            icon: Icons.airline_seat_recline_extra_rounded,
                            iconColor: chipIconColor,
                            label: _getCabinClassName(search.cabinClass, isArabic),
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

class _FlightResultsBanner extends StatelessWidget {
  const _FlightResultsBanner({
    required this.count,
    required this.totalCount,
    required this.filters,
    this.searchId,
  });

  final int count;
  final int totalCount;
  final FlightFilterState filters;
  final String? searchId;

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
                      '$count ${context.tr(count == 1 ? 'flightOption' : 'flightOptions')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    if (filters.isActive)
                      Text(
                        '(${context.tr('filtersTitle')}: $totalCount)',
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
                      ? 'مقارنة أسعار مباشرة بدون رسوم إضافية'
                      : 'Direct fare comparison · No hidden fees',
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
          if (searchId != null && searchId!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                searchId!.length > 14
                    ? '${searchId!.substring(0, 10)}…'
                    : searchId!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.muted : AppColors.orange,
                ),
              ),
            ),
          ],
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

class _FlightTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.5;
    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      if (startX < size.width / 2 - 16 || startX > size.width / 2 + 16) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint,
        );
      }
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

String _getCabinClassName(int cabinClass, bool isAr) => getCabinClassName(cabinClass, isAr);

String _getTripTypeLabel(FlightSearch search, bool isAr) {
  if (search.returnDate != null || search.tripType == 'round-trip') {
    return isAr ? 'ذهاب وعودة' : 'Round Trip';
  }
  return isAr ? 'ذهاب فقط' : 'One Way';
}

class _QuickFilterStrip extends StatelessWidget {
  const _QuickFilterStrip({
    required this.state,
    required this.currentCurrency,
    required this.onCurrencyTap,
    required this.onFilterTap,
    required this.onToggleDirect,
    required this.onToggleBaggage,
    required this.onToggleRefundable,
    required this.onToggleCheapest,
    required this.onToggleShortest,
    required this.onReset,
  });

  final FlightFilterState state;
  final String currentCurrency;
  final VoidCallback onCurrencyTap;
  final VoidCallback onFilterTap;
  final VoidCallback onToggleDirect;
  final VoidCallback onToggleBaggage;
  final VoidCallback onToggleRefundable;
  final VoidCallback onToggleCheapest;
  final VoidCallback onToggleShortest;
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
                  ? '${context.tr('filtersTitle')} (${state.activeCount})'
                  : context.tr('filtersTitle'),
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
          _QuickChip(
            icon: Icons.flight_takeoff_rounded,
            label: context.tr('direct'),
            selected: state.stops == FlightStopsMode.direct,
            onTap: onToggleDirect,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.luggage_outlined,
            label: context.tr('checkedBaggageOnly'),
            selected: state.includesCheckedBaggage,
            onTap: onToggleBaggage,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.published_with_changes_rounded,
            label: context.tr('refundable'),
            selected: state.refundableOnly,
            onTap: onToggleRefundable,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.savings_outlined,
            label: context.tr('sortCheapest'),
            selected: state.sort == FlightSortMode.cheapest,
            onTap: onToggleCheapest,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.timer_outlined,
            label: context.tr('sortShortest'),
            selected: state.sort == FlightSortMode.shortest,
            onTap: onToggleShortest,
          ),
          if (state.isActive) ...[
            const SizedBox(width: 8),
            ActionChip(
              onPressed: onReset,
              avatar: const Icon(Icons.close_rounded, size: 15, color: AppColors.orange),
              label: Text(
                context.tr('resetFilters'),
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

class _QuickChip extends StatelessWidget {
  const _QuickChip({
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
