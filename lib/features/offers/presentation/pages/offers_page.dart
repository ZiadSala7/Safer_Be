import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../home/presentation/widgets/travel_cards.dart';
import '../../data/repositories/api_offers_repository.dart';
import '../../domain/entities/marketing_offer.dart';
import '../../domain/entities/offer_filter.dart';
import '../../domain/repositories/offers_repository.dart';
import '../widgets/offer_details_sheet.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({
    super.key,
    this.repository,
    this.initialOfferId,
    this.isStandalone = false,
  });

  final OffersRepository? repository;
  final String? initialOfferId;
  final bool isStandalone;

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late final OffersRepository _repository;
  OfferFilter selected = OfferFilter.all;
  bool _loading = true;
  String? _errorMessage;
  List<MarketingOffer> _offers = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiOffersRepository();
    _loadOffers();
  }

  Future<void> _loadOffers({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getAvailableOffers(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _offers = list;
          _loading = false;
        });
        if (widget.initialOfferId != null && list.isNotEmpty) {
          final target = list.cast<MarketingOffer?>().firstWhere(
            (o) => o?.id.toString() == widget.initialOfferId,
            orElse: () => null,
          );
          if (target != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) OfferDetailsSheet.show(context, offer: target);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<MarketingOffer> get _filteredOffers {
    if (selected == OfferFilter.all) return _offers;
    final key = selected.name;
    return _offers
        .where((offer) => offer.category == key || offer.category == 'all')
        .toList();
  }

  int _countForFilter(OfferFilter filter) {
    if (filter == OfferFilter.all) return _offers.length;
    final key = filter.name;
    return _offers
        .where((offer) => offer.category == key || offer.category == 'all')
        .length;
  }

  IconData _iconForFilter(OfferFilter filter) {
    switch (filter) {
      case OfferFilter.all:
        return Icons.auto_awesome_rounded;
      case OfferFilter.flights:
        return Icons.flight_takeoff_rounded;
      case OfferFilter.hotels:
        return Icons.hotel_rounded;
      case OfferFilter.transfers:
        return Icons.directions_car_filled_rounded;
      case OfferFilter.domestic:
        return Icons.explore_rounded;
    }
  }

  Widget _buildHeroBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
              : const [Color(0xFF1E2633), Color(0xFF2C3E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      context.tr('verifiedLiveDeals'),
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.tr('liveApiSynced'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('promoHeadline'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('promoSubtitle'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (_offers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_offers.length} ${context.tr('activeDealsCount')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    final filterKeys = ['all', 'flights', 'hotels', 'transfers', 'domestic'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: OfferFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = OfferFilter.values[index];
          final isSelected = selected == filter;
          final count = _countForFilter(filter);
          final label = context.tr(filterKeys[index]);
          final displayText = count > 0 ? '$label ($count)' : label;

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () => setState(() => selected = filter),
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.orange
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.orange
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForFilter(filter),
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredOffers;

    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _loadOffers(forceRefresh: true),
        color: AppColors.orange,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Page Header Title Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('offers'),
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('offersSubtitle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_loading && _offers.isNotEmpty)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.orange,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Hero Promotion Banner
            SliverToBoxAdapter(child: _buildHeroBanner(context, isDark)),

            // Filter Chips Bar
            SliverToBoxAdapter(child: _buildFilterChips(context, isDark)),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // Active Results Count Bar
            if (filtered.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        selected == OfferFilter.all
                            ? context.tr('allOffersShown')
                            : context.tr(selected.name),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filtered.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Content States
            if (_loading && _offers.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
              )
            else if (_errorMessage != null && _offers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: RequestStateView(
                  icon: Icons.cloud_off_rounded,
                  title: context.tr('offersLoadError'),
                  message: _errorMessage!,
                  actionLabel: context.tr('retry'),
                  onAction: () => _loadOffers(forceRefresh: true),
                ),
              )
            else if (_offers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: RequestStateView(
                  icon: Icons.campaign_outlined,
                  title: context.tr('noActiveOffers'),
                  message: context.tr('noActiveOffersDesc'),
                  actionLabel: context.tr('refreshOffers'),
                  onAction: () => _loadOffers(forceRefresh: true),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: RequestStateView(
                  icon: Icons.filter_alt_off_rounded,
                  title: context.tr('noOffersForFilter'),
                  message: context.tr('noOffersForFilterBody'),
                  actionLabel: context.tr('viewAllOffers'),
                  onAction: () => setState(() => selected = OfferFilter.all),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => OfferCard(
                    offer: filtered[index],
                    large: true,
                    onTap: () => OfferDetailsSheet.show(
                      context,
                      offer: filtered[index],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.isStandalone) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: body,
      );
    }
    return body;
  }
}
