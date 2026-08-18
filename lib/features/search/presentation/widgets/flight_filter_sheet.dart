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
    this.priceMin,
    this.priceMax,
  });

  FlightSortMode sort;
  FlightStopsMode stops;
  Set<String> airlines;
  Set<String> departureSlots;
  Set<String> arrivalSlots;
  bool includesCheckedBaggage;
  double? priceMin;
  double? priceMax;

  FlightFilterState copy() => FlightFilterState(
    sort: sort,
    stops: stops,
    airlines: Set.of(airlines),
    departureSlots: Set.of(departureSlots),
    arrivalSlots: Set.of(arrivalSlots),
    includesCheckedBaggage: includesCheckedBaggage,
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
      priceMin != null ||
      priceMax != null;

  int get activeCount {
    var c = 0;
    if (stops != FlightStopsMode.any) c++;
    if (airlines.isNotEmpty) c++;
    if (departureSlots.isNotEmpty) c++;
    if (arrivalSlots.isNotEmpty) c++;
    if (includesCheckedBaggage) c++;
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;

  @override
  void initState() {
    super.initState();
    _state = widget.state.copy();
    _airlines = Set.of(_state.airlines);
    _departureSlots = Set.of(_state.departureSlots);
    _arrivalSlots = Set.of(_state.arrivalSlots);
    _minPrice = TextEditingController(text: _formatPrice(_state.priceMin));
    _maxPrice = TextEditingController(text: _formatPrice(_state.priceMax));
  }

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
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
      _minPrice.clear();
      _maxPrice.clear();
    });
  }

  void _applyPriceFields() {
    _state.priceMin = double.tryParse(_minPrice.text.trim());
    _state.priceMax = double.tryParse(_maxPrice.text.trim());
  }

  String _formatPrice(double? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.84,
    minChildSize: 0.45,
    maxChildSize: 0.94,
    expand: false,
    builder: (context, controller) => Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('filtersTitle'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (_state.isActive)
                TextButton(
                  onPressed: _reset,
                  child: Text(context.tr('resetFilters')),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _Section(
                title: context.tr('sortBy'),
                child: _SortChips(
                  value: _state.sort,
                  onChanged: (v) => setState(() => _state.sort = v),
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: context.tr('stops'),
                child: _StopChips(
                  value: _state.stops,
                  onChanged: (v) => setState(() => _state.stops = v),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.tr('checkedBaggageOnly'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                value: _state.includesCheckedBaggage,
                onChanged: (v) =>
                    setState(() => _state.includesCheckedBaggage = v),
                activeThumbColor: AppColors.teal,
              ),
              const SizedBox(height: 10),
              _Section(
                title: context.tr('priceRange'),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPrice,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.tr('minPrice'),
                        ),
                        onChanged: (_) => setState(_applyPriceFields),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _maxPrice,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.tr('maxPrice'),
                        ),
                        onChanged: (_) => setState(_applyPriceFields),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: context.tr('departureTime'),
                child: _TimeChips(
                  selected: _departureSlots,
                  onChanged: (v) => setState(() {
                    _toggle(_departureSlots, v);
                    _state.departureSlots = _departureSlots;
                  }),
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: context.tr('arrivalTime'),
                child: _TimeChips(
                  selected: _arrivalSlots,
                  onChanged: (v) => setState(() {
                    _toggle(_arrivalSlots, v);
                    _state.arrivalSlots = _arrivalSlots;
                  }),
                ),
              ),
              if (_detectedAirlines.length > 1) ...[
                const SizedBox(height: 20),
                _Section(
                  title: context.tr('airlines'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _detectedAirlines.map((item) {
                      final selected = _airlines.contains(item.code);
                      return FilterChip(
                        label: Text(item.name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _toggle(_airlines, item.code);
                            _state.airlines = _airlines;
                          });
                        },
                        selectedColor: AppColors.teal.withValues(alpha: .15),
                        checkmarkColor: AppColors.teal,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  _applyPriceFields();
                  Navigator.pop(context, _state);
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                child: Text(
                  _state.isActive
                      ? context
                            .tr('showResults')
                            .replaceAll('{count}', '${_state.activeCount}')
                      : context.tr('showAll'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _toggle(Set<String> values, String value) {
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      child,
    ],
  );
}

class _SortChips extends StatelessWidget {
  const _SortChips({required this.value, required this.onChanged});
  final FlightSortMode value;
  final ValueChanged<FlightSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (FlightSortMode.best, Icons.star_rounded, context.tr('sortBest')),
      (
        FlightSortMode.cheapest,
        Icons.savings_outlined,
        context.tr('sortCheapest'),
      ),
      (
        FlightSortMode.shortest,
        Icons.timer_rounded,
        context.tr('sortShortest'),
      ),
    ];
    return Row(
      children: items.map((item) {
        final selected = value == item.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.teal.withValues(alpha: .12)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.teal : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                onTap: () => onChanged(item.$1),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Icon(
                        item.$2,
                        size: 22,
                        color: selected ? AppColors.teal : AppColors.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected ? AppColors.teal : AppColors.muted,
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

class _StopChips extends StatelessWidget {
  const _StopChips({required this.value, required this.onChanged});
  final FlightStopsMode value;
  final ValueChanged<FlightStopsMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (FlightStopsMode.any, context.tr('anyStops')),
      (FlightStopsMode.direct, context.tr('direct')),
      (FlightStopsMode.oneStopOrLess, context.tr('oneStopOrLess')),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final selected = value == item.$1;
        return ChoiceChip(
          label: Text(item.$2),
          selected: selected,
          onSelected: (_) => onChanged(item.$1),
          selectedColor: AppColors.teal.withValues(alpha: .15),
          checkmarkColor: AppColors.teal,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.teal : null,
          ),
        );
      }).toList(),
    );
  }
}

class _TimeChips extends StatelessWidget {
  const _TimeChips({required this.selected, required this.onChanged});
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('before-6am', Icons.nightlight_round, context.tr('before6am')),
      ('6am-12pm', Icons.wb_sunny_rounded, context.tr('time6to12')),
      ('12pm-6pm', Icons.wb_cloudy_rounded, context.tr('time12to6')),
      ('after-6pm', Icons.nights_stay_rounded, context.tr('after6pm')),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected.contains(item.$1);
        return FilterChip(
          avatar: Icon(
            item.$2,
            size: 18,
            color: isSelected ? AppColors.teal : AppColors.muted,
          ),
          label: Text(item.$3),
          selected: isSelected,
          onSelected: (_) => onChanged(item.$1),
          selectedColor: AppColors.teal.withValues(alpha: .15),
          checkmarkColor: AppColors.teal,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.teal : null,
          ),
        );
      }).toList(),
    );
  }
}
