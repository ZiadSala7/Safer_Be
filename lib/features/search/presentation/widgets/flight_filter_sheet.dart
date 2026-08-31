import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/flight_offer.dart';

enum FlightSortMode { best, cheapest, shortest }

enum FlightStopsMode { any, direct, oneStopOrLess }

class FlightFilterState {
  FlightFilterState({
    this.sort = FlightSortMode.best,
    this.stops = FlightStopsMode.any,
    this.airlines = const {},
    this.departureSlots = const {},
    this.arrivalSlots = const {},
    this.includesCheckedBaggage = false,
    this.refundableOnly = false,
    this.priceMin,
    this.priceMax,
  });

  FlightSortMode sort;
  FlightStopsMode stops;
  Set<String> airlines;
  Set<String> departureSlots;
  Set<String> arrivalSlots;
  bool includesCheckedBaggage;
  bool refundableOnly;
  double? priceMin;
  double? priceMax;

  FlightFilterState copy() => FlightFilterState(
    sort: sort,
    stops: stops,
    airlines: Set.of(airlines),
    departureSlots: Set.of(departureSlots),
    arrivalSlots: Set.of(arrivalSlots),
    includesCheckedBaggage: includesCheckedBaggage,
    refundableOnly: refundableOnly,
    priceMin: priceMin,
    priceMax: priceMax,
  );

  bool get shouldSearchAirlines => airlines.isNotEmpty;

  bool get isActive =>
      sort != FlightSortMode.best ||
      stops != FlightStopsMode.any ||
      airlines.isNotEmpty ||
      departureSlots.isNotEmpty ||
      arrivalSlots.isNotEmpty ||
      includesCheckedBaggage ||
      refundableOnly ||
      priceMin != null ||
      priceMax != null;

  int get activeCount {
    var c = 0;
    if (sort != FlightSortMode.best) c++;
    if (stops != FlightStopsMode.any) c++;
    if (airlines.isNotEmpty) c++;
    if (departureSlots.isNotEmpty) c++;
    if (arrivalSlots.isNotEmpty) c++;
    if (includesCheckedBaggage) c++;
    if (refundableOnly) c++;
    if (priceMin != null || priceMax != null) c++;
    return c;
  }

  void reset() {
    sort = FlightSortMode.best;
    stops = FlightStopsMode.any;
    airlines = {};
    departureSlots = {};
    arrivalSlots = {};
    includesCheckedBaggage = false;
    refundableOnly = false;
    priceMin = null;
    priceMax = null;
  }

  List<FlightOffer> apply(List<FlightOffer> offers) {
    var result = List<FlightOffer>.of(offers);

    switch (stops) {
      case FlightStopsMode.any:
        break;
      case FlightStopsMode.direct:
        result = result.where((o) => o.stops == 0).toList();
      case FlightStopsMode.oneStopOrLess:
        result = result.where((o) => o.stops <= 1).toList();
    }

    if (airlines.isNotEmpty) {
      result = result
          .where((o) => airlines.any((airline) => o.matchesAirline(airline)))
          .toList();
    }
    if (includesCheckedBaggage) {
      result = result.where((o) => o.hasCheckedBaggage).toList();
    }
    if (refundableOnly) {
      result = result.where((o) => o.refundable).toList();
    }
    if (priceMin != null) {
      result = result.where((o) => o.price >= priceMin!).toList();
    }
    if (priceMax != null) {
      result = result.where((o) => o.price <= priceMax!).toList();
    }
    if (departureSlots.isNotEmpty) {
      result = result
          .where((o) => _matchesAnySlot(o.departureTime, departureSlots))
          .toList();
    }
    if (arrivalSlots.isNotEmpty) {
      result = result
          .where((o) => _matchesAnySlot(o.arrivalTime, arrivalSlots))
          .toList();
    }

    switch (sort) {
      case FlightSortMode.cheapest:
        result.sort((a, b) => a.price.compareTo(b.price));
      case FlightSortMode.shortest:
        result.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
      case FlightSortMode.best:
        result.sort((a, b) {
          final labelCompare = b.labels.length.compareTo(a.labels.length);
          if (labelCompare != 0) return labelCompare;
          return a.price.compareTo(b.price);
        });
    }

    return result;
  }

  static bool _matchesAnySlot(DateTime? value, Set<String> slots) {
    if (value == null) return false;
    final hour = value.hour;
    return slots.any((slot) {
      switch (slot) {
        case 'before-6am':
          return hour < 6;
        case '6am-12pm':
          return hour >= 6 && hour < 12;
        case '12pm-6pm':
          return hour >= 12 && hour < 18;
        case 'after-6pm':
          return hour >= 18;
        default:
          return false;
      }
    });
  }
}

extension on FlightOffer {
  bool matchesAirline(String value) {
    final needle = value.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return airline.toLowerCase().contains(needle) ||
        (airlineCode?.toLowerCase() == needle);
  }
}

class FlightFilterSheet extends StatefulWidget {
  const FlightFilterSheet({
    required this.state,
    required this.allOffers,
    super.key,
  });

  final FlightFilterState state;
  final List<FlightOffer> allOffers;

  static Future<FlightFilterState?> show(
    BuildContext context, {
    required FlightFilterState state,
    required List<FlightOffer> allOffers,
  }) => showModalBottomSheet<FlightFilterState>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FlightFilterSheet(state: state, allOffers: allOffers),
  );

  @override
  State<FlightFilterSheet> createState() => _FlightFilterSheetState();
}

class _FlightFilterSheetState extends State<FlightFilterSheet> {
  late FlightFilterState _state;
  late Set<String> _airlines;
  late Set<String> _departureSlots;
  late Set<String> _arrivalSlots;
  late double _minBound;
  late double _maxBound;
  late RangeValues _currentRange;
  late final String _currency;

  @override
  void initState() {
    super.initState();
    _state = widget.state.copy();
    _airlines = Set.of(_state.airlines);
    _departureSlots = Set.of(_state.departureSlots);
    _arrivalSlots = Set.of(_state.arrivalSlots);

    _currency = widget.allOffers.isNotEmpty
        ? widget.allOffers.first.currency
        : 'SAR';

    double minP = double.infinity;
    double maxP = 0;
    for (final o in widget.allOffers) {
      if (o.price < minP) minP = o.price.toDouble();
      if (o.price > maxP) maxP = o.price.toDouble();
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
  }

  Set<_AirlineFilterOption> get _detectedAirlines {
    final values = <_AirlineFilterOption>{};
    for (final o in widget.allOffers) {
      if (o.airline.isEmpty) continue;
      values.add(_AirlineFilterOption(o.airlineCode ?? o.airline, o.airline));
    }
    return values;
  }

  void _reset() {
    setState(() {
      _state.reset();
      _airlines.clear();
      _departureSlots.clear();
      _arrivalSlots.clear();
      _currentRange = RangeValues(_minBound, _maxBound);
    });
  }

  void _syncState() {
    _state.airlines = _airlines;
    _state.departureSlots = _departureSlots;
    _state.arrivalSlots = _arrivalSlots;
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
    return _state.apply(widget.allOffers).length;
  }

  void _toggle(Set<String> values, String value) {
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
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
                        context.tr('filtersTitle'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _state.isActive
                            ? '${_state.activeCount} active'
                            : '${widget.allOffers.length} available',
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
                      context.tr('resetFilters'),
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
          // Scrollable filter body
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
                _SortCards(
                  value: _state.sort,
                  accentColor: primaryAccent,
                  onChanged: (v) => setState(() => _state.sort = v),
                ),

                const SizedBox(height: 22),

                // 2. Stops Section
                _SectionTitle(
                  icon: Icons.flight_takeoff_rounded,
                  title: context.tr('stops'),
                  accentColor: primaryAccent,
                ),
                const SizedBox(height: 10),
                _StopsCards(
                  value: _state.stops,
                  accentColor: primaryAccent,
                  onChanged: (v) => setState(() => _state.stops = v),
                ),

                const SizedBox(height: 22),

                // 3. Price Range Slider
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

                const SizedBox(height: 22),

                // 4. Inclusions & Policies (Baggage & Refundable)
                _SectionTitle(
                  icon: Icons.verified_user_outlined,
                  title: 'Fare Inclusions & Policy',
                  accentColor: primaryAccent,
                ),
                const SizedBox(height: 10),
                _ToggleCard(
                  icon: Icons.luggage_outlined,
                  title: context.tr('checkedBaggageOnly'),
                  subtitle: 'Includes 1 or more checked bags in fare',
                  value: _state.includesCheckedBaggage,
                  accentColor: primaryAccent,
                  onChanged: (v) =>
                      setState(() => _state.includesCheckedBaggage = v),
                ),
                const SizedBox(height: 8),
                _ToggleCard(
                  icon: Icons.published_with_changes_rounded,
                  title: context.tr('refundable'),
                  subtitle: 'Only flexible fares with refund options',
                  value: _state.refundableOnly,
                  accentColor: primaryAccent,
                  onChanged: (v) =>
                      setState(() => _state.refundableOnly = v),
                ),

                const SizedBox(height: 22),

                // 5. Departure Time Slots
                _SectionTitle(
                  icon: Icons.wb_twilight_rounded,
                  title: context.tr('departureTime'),
                  accentColor: primaryAccent,
                ),
                const SizedBox(height: 10),
                _TimeSlotsGrid(
                  selected: _departureSlots,
                  accentColor: primaryAccent,
                  onChanged: (v) => setState(() {
                    _toggle(_departureSlots, v);
                    _state.departureSlots = _departureSlots;
                  }),
                ),

                const SizedBox(height: 22),

                // 6. Arrival Time Slots
                _SectionTitle(
                  icon: Icons.nights_stay_outlined,
                  title: context.tr('arrivalTime'),
                  accentColor: primaryAccent,
                ),
                const SizedBox(height: 10),
                _TimeSlotsGrid(
                  selected: _arrivalSlots,
                  accentColor: primaryAccent,
                  onChanged: (v) => setState(() {
                    _toggle(_arrivalSlots, v);
                    _state.arrivalSlots = _arrivalSlots;
                  }),
                ),

                if (_detectedAirlines.length > 1) ...[
                  const SizedBox(height: 22),
                  // 7. Airlines Section
                  _SectionTitle(
                    icon: Icons.flight_rounded,
                    title: context.tr('airlines'),
                    accentColor: primaryAccent,
                    trailing: _airlines.isNotEmpty
                        ? TextButton(
                            onPressed: () => setState(() => _airlines.clear()),
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
                    children: _detectedAirlines.map((item) {
                      final selected = _airlines.contains(item.code);
                      return FilterChip(
                        avatar: CircleAvatar(
                          backgroundColor: selected
                              ? primaryAccent
                              : AppColors.muted.withValues(alpha: .15),
                          child: Text(
                            item.code.substring(0, math.min(2, item.code.length)),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: selected ? Colors.white : AppColors.navySoft,
                            ),
                          ),
                        ),
                        label: Text(item.name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _toggle(_airlines, item.code);
                            _state.airlines = _airlines;
                          });
                        },
                        selectedColor: primaryAccent.withValues(alpha: .15),
                        checkmarkColor: primaryAccent,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
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
          // Bottom Sticky Action Button with Live Result Count
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
                        count > 0
                            ? 'Show $count Flights'
                            : context.tr('showAll'),
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

class _AirlineFilterOption {
  const _AirlineFilterOption(this.code, this.name);

  final String code;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is _AirlineFilterOption && other.code == code;

  @override
  int get hashCode => code.hashCode;
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

class _SortCards extends StatelessWidget {
  const _SortCards({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final FlightSortMode value;
  final Color accentColor;
  final ValueChanged<FlightSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (FlightSortMode.best, Icons.auto_awesome_rounded, context.tr('sortBest'), 'Recommended'),
      (FlightSortMode.cheapest, Icons.savings_outlined, context.tr('sortCheapest'), 'Lowest price'),
      (FlightSortMode.shortest, Icons.timer_outlined, context.tr('sortShortest'), 'Fastest route'),
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

class _StopsCards extends StatelessWidget {
  const _StopsCards({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final FlightStopsMode value;
  final Color accentColor;
  final ValueChanged<FlightStopsMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (FlightStopsMode.any, Icons.all_inclusive_rounded, context.tr('anyStops'), 'All flight options'),
      (FlightStopsMode.direct, Icons.flight_takeoff_rounded, context.tr('direct'), 'Non-stop flights'),
      (FlightStopsMode.oneStopOrLess, Icons.connecting_airports_rounded, context.tr('oneStopOrLess'), '1 stop max'),
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
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
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
                        size: 20,
                        color: selected ? accentColor : AppColors.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
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
                          fontSize: 9,
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

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: value
          ? accentColor.withValues(alpha: .08)
          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .4),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: value
            ? accentColor.withValues(alpha: .4)
            : Theme.of(context).dividerColor.withValues(alpha: .2),
        width: 1.2,
      ),
    ),
    child: SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: value
              ? accentColor.withValues(alpha: .15)
              : AppColors.muted.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: value ? accentColor : AppColors.muted,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.muted,
          fontSize: 11,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: accentColor,
    ),
  );
}

class _TimeSlotsGrid extends StatelessWidget {
  const _TimeSlotsGrid({
    required this.selected,
    required this.accentColor,
    required this.onChanged,
  });

  final Set<String> selected;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('before-6am', Icons.nightlight_round, context.tr('before6am'), '00:00 - 06:00'),
      ('6am-12pm', Icons.wb_sunny_rounded, context.tr('time6to12'), '06:00 - 12:00'),
      ('12pm-6pm', Icons.wb_cloudy_rounded, context.tr('time12to6'), '12:00 - 18:00'),
      ('after-6pm', Icons.nights_stay_rounded, context.tr('after6pm'), '18:00 - 24:00'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) {
        final isSelected = selected.contains(item.$1);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(item.$1),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: .12)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.$2,
                    size: 20,
                    color: isSelected ? accentColor : AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? accentColor : null,
                          ),
                        ),
                        Text(
                          item.$4,
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
