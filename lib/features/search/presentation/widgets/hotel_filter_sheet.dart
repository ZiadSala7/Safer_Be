import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/hotel_offer.dart';

enum HotelSortMode { best, cheapest, highestRated }

enum HotelStarFilter { any, threePlus, fourPlus, fiveOnly }

class HotelFilterState {
  HotelFilterState({
    this.sort = HotelSortMode.best,
    this.starFilter = HotelStarFilter.any,
    this.suppliers = const {},
    this.freeCancellationOnly = false,
    this.priceMin,
    this.priceMax,
  });

  HotelSortMode sort;
  HotelStarFilter starFilter;
  Set<String> suppliers;
  bool freeCancellationOnly;
  double? priceMin;
  double? priceMax;

  HotelFilterState copy() => HotelFilterState(
    sort: sort,
    starFilter: starFilter,
    suppliers: Set.of(suppliers),
    freeCancellationOnly: freeCancellationOnly,
    priceMin: priceMin,
    priceMax: priceMax,
  );

  bool get isActive =>
      sort != HotelSortMode.best ||
      starFilter != HotelStarFilter.any ||
      suppliers.isNotEmpty ||
      freeCancellationOnly ||
      priceMin != null ||
      priceMax != null;

  int get activeCount {
    var c = 0;
    if (sort != HotelSortMode.best) c++;
    if (starFilter != HotelStarFilter.any) c++;
    if (suppliers.isNotEmpty) c++;
    if (freeCancellationOnly) c++;
    if (priceMin != null || priceMax != null) c++;
    return c;
  }

  void reset() {
    sort = HotelSortMode.best;
    starFilter = HotelStarFilter.any;
    suppliers = {};
    freeCancellationOnly = false;
    priceMin = null;
    priceMax = null;
  }

  List<HotelOffer> apply(List<HotelOffer> offers) {
    var result = List<HotelOffer>.of(offers);

    switch (starFilter) {
      case HotelStarFilter.any:
        break;
      case HotelStarFilter.threePlus:
        result = result.where((h) => h.rating >= 3).toList();
      case HotelStarFilter.fourPlus:
        result = result.where((h) => h.rating >= 4).toList();
      case HotelStarFilter.fiveOnly:
        result = result.where((h) => h.rating >= 5).toList();
    }

    if (suppliers.isNotEmpty) {
      result = result
          .where(
            (h) => suppliers.any(
              (s) => h.supplier.toLowerCase() == s.toLowerCase(),
            ),
          )
          .toList();
    }

    if (priceMin != null) {
      result = result.where((h) => h.price >= priceMin!).toList();
    }
    if (priceMax != null) {
      result = result.where((h) => h.price <= priceMax!).toList();
    }

    switch (sort) {
      case HotelSortMode.cheapest:
        result.sort((a, b) => a.price.compareTo(b.price));
      case HotelSortMode.highestRated:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case HotelSortMode.best:
        result.sort((a, b) {
          final ratingComp = b.rating.compareTo(a.rating);
          if (ratingComp != 0) return ratingComp;
          return a.price.compareTo(b.price);
        });
    }

    return result;
  }
}

class HotelFilterSheet extends StatefulWidget {
  const HotelFilterSheet({
    required this.state,
    required this.offers,
    super.key,
  });

  final HotelFilterState state;
  final List<HotelOffer> offers;

  static Future<HotelFilterState?> show(
    BuildContext context, {
    required HotelFilterState state,
    required List<HotelOffer> offers,
  }) => showModalBottomSheet<HotelFilterState>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HotelFilterSheet(state: state, offers: offers),
  );

  @override
  State<HotelFilterSheet> createState() => _HotelFilterSheetState();
}

class _HotelFilterSheetState extends State<HotelFilterSheet> {
  late HotelFilterState _state;
  final Set<String> _suppliers = {};
  late final List<String> _detectedSuppliers;
  late double _minBound;
  late double _maxBound;
  late RangeValues _currentRange;
  late final String _currency;

  @override
  void initState() {
    super.initState();
    _state = widget.state.copy();
    _suppliers.addAll(_state.suppliers);

    _currency = widget.offers.isNotEmpty ? widget.offers.first.currency : 'SAR';

    double minP = double.infinity;
    double maxP = 0;
    for (final h in widget.offers) {
      if (h.price < minP) minP = h.price.toDouble();
      if (h.price > maxP) maxP = h.price.toDouble();
    }
    if (minP == double.infinity) minP = 0;
    if (maxP <= minP) maxP = minP + 500;

    _minBound = (minP / 10).floor() * 10.0;
    _maxBound = (maxP / 10).ceil() * 10.0;

    final startVal = math.max(_minBound, _state.priceMin ?? _minBound);
    final endVal = math.min(_maxBound, _state.priceMax ?? _maxBound);
    _currentRange = RangeValues(
      startVal < endVal ? startVal : _minBound,
      endVal > startVal ? endVal : _maxBound,
    );

    final supplierSet = <String>{};
    for (final h in widget.offers) {
      if (h.supplier.isNotEmpty) {
        supplierSet.add(h.supplier);
      }
    }
    _detectedSuppliers = supplierSet.toList()..sort();
  }

  void _reset() {
    setState(() {
      _state.reset();
      _suppliers.clear();
      _currentRange = RangeValues(_minBound, _maxBound);
    });
  }

  void _syncState() {
    _state.suppliers = _suppliers;
    if (_currentRange.start > _minBound) {
      _state.priceMin = _currentRange.start;
    } else {
      _state.priceMin = null;
    }
    if (_currentRange.end < _maxBound) {
      _state.priceMax = _currentRange.end;
    } else {
      _state.priceMax = null;
    }
  }

  int get _matchingCount {
    _syncState();
    return _state.apply(widget.offers).length;
  }

  void _toggleSupplier(String s) {
    setState(() {
      if (_suppliers.contains(s)) {
        _suppliers.remove(s);
      } else {
        _suppliers.add(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncState();
    final count = _matchingCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppColors.teal : AppColors.orange;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: primaryAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('filterStays'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _state.isActive
                            ? '${_state.activeCount} active'
                            : '${widget.offers.length} stays available',
                        style: TextStyle(
                          fontSize: 12,
                          color: _state.isActive ? primaryAccent : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_state.isActive)
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      context.tr('resetAll'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.orange,
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // 1. Sort Section
                _SectionTitle(
                  icon: Icons.swap_vert_rounded,
                  title: context.tr('sortBy'),
                  accentColor: primaryAccent,
                ),
                const SizedBox(height: 10),
                _HotelSortCards(
                  value: _state.sort,
                  accentColor: primaryAccent,
                  onChanged: (v) => setState(() => _state.sort = v),
                ),

                const SizedBox(height: 22),

                // 2. Star Rating Cards
                _SectionTitle(
                  icon: Icons.hotel_class_rounded,
                  title: context.tr('starRating'),
                  accentColor: primaryAccent,
                ),
                const SizedBox(height: 10),
                _StarRatingGrid(
                  value: _state.starFilter,
                  accentColor: primaryAccent,
                  onChanged: (v) => setState(() => _state.starFilter = v),
                ),

                const SizedBox(height: 22),

                // 3. Price Range
                _SectionTitle(
                  icon: Icons.payments_outlined,
                  title: context.tr('priceRange'),
                  accentColor: primaryAccent,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentRange.start.toInt()} - ${_currentRange.end.toInt()} $_currency',
                      style: TextStyle(
                        color: primaryAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  values: _currentRange,
                  min: _minBound,
                  max: _maxBound,
                  divisions: math.max(1, ((_maxBound - _minBound) / 20).round()),
                  activeColor: primaryAccent,
                  inactiveColor: primaryAccent.withValues(alpha: .18),
                  labels: RangeLabels(
                    '${_currentRange.start.toInt()} $_currency',
                    '${_currentRange.end.toInt()} $_currency',
                  ),
                  onChanged: (range) {
                    setState(() => _currentRange = range);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Min: ${_minBound.toInt()} $_currency',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Max: ${_maxBound.toInt()} $_currency',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                if (_detectedSuppliers.length > 1) ...[
                  const SizedBox(height: 22),
                  // 4. Suppliers / Providers Section
                  _SectionTitle(
                    icon: Icons.cloud_outlined,
                    title: context.tr('provider'),
                    accentColor: primaryAccent,
                    trailing: _suppliers.isNotEmpty
                        ? TextButton(
                            onPressed: () => setState(() => _suppliers.clear()),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _detectedSuppliers.map((supplier) {
                      final selected = _suppliers.contains(supplier);
                      return FilterChip(
                        avatar: Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: selected ? primaryAccent : AppColors.muted,
                        ),
                        label: Text(supplier.toUpperCase()),
                        selected: selected,
                        onSelected: (_) => _toggleSupplier(supplier),
                        selectedColor: primaryAccent.withValues(alpha: .15),
                        checkmarkColor: primaryAccent,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: selected ? primaryAccent : null,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? primaryAccent
                                : Theme.of(context).dividerColor.withValues(alpha: .3),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          // Bottom Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: .3),
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    _syncState();
                    Navigator.pop(context, _state);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    shadowColor: primaryAccent.withValues(alpha: 0.35),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        count > 0 ? 'Show $count Stays' : context.tr('showAll'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.accentColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: accentColor),
      const SizedBox(width: 8),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      if (trailing != null) ...[
        const Spacer(),
        trailing!,
      ],
    ],
  );
}

class _HotelSortCards extends StatelessWidget {
  const _HotelSortCards({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final HotelSortMode value;
  final Color accentColor;
  final ValueChanged<HotelSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (HotelSortMode.best, Icons.auto_awesome_rounded, context.tr('bestDeals'), 'Best match'),
      (HotelSortMode.cheapest, Icons.savings_outlined, context.tr('cheapestFirst'), 'Lowest price'),
      (HotelSortMode.highestRated, Icons.star_rounded, context.tr('rating'), 'Top guest review'),
    ];
    return Row(
      children: items.map((item) {
        final selected = value == item.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(item.$1),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withValues(alpha: .12)
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? accentColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        item.$2,
                        size: 22,
                        color: selected ? accentColor : AppColors.muted,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: selected ? accentColor : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? accentColor.withValues(alpha: .85)
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StarRatingGrid extends StatelessWidget {
  const _StarRatingGrid({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final HotelStarFilter value;
  final Color accentColor;
  final ValueChanged<HotelStarFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (HotelStarFilter.any, 'All', 'Any star rating', Icons.hotel_rounded, const Color(0xFF64748B)),
      (HotelStarFilter.threePlus, '3★+', 'Good (3 stars+)', Icons.star_half_rounded, const Color(0xFFF59E0B)),
      (HotelStarFilter.fourPlus, '4★+', 'Very Good (4 stars+)', Icons.star_rounded, const Color(0xFFF59E0B)),
      (HotelStarFilter.fiveOnly, '5★', 'Luxury (5 stars)', Icons.workspace_premium_rounded, const Color(0xFFFFB020)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) {
        final selected = value == item.$1;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(item.$1),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withValues(alpha: .12)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? accentColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.$4,
                    size: 22,
                    color: selected ? accentColor : item.$5,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: selected ? accentColor : null,
                          ),
                        ),
                        Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
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
      }).toList(),
    );
  }
}
