part of 'travel_search_card.dart';

class _HotelForm extends StatefulWidget {
  const _HotelForm({super.key});

  @override
  State<_HotelForm> createState() => _HotelFormState();
}

class _HotelFormState extends State<_HotelForm> {
  TravelCity city = const TravelCity(
    code: '113116',
    name: 'Jeddah',
    country: 'Saudi Arabia',
  );
  DateTime checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime checkOut = DateTime.now().add(const Duration(days: 3));
  int adults = 2;
  int children = 0;

  Future<void> editCity() async {
    final value = await Navigator.push<TravelCity>(
      context,
      MaterialPageRoute(builder: (_) => const CityPickerPage()),
    );
    if (value != null) setState(() => city = value);
  }

  Future<void> pick(bool arrival) async {
    final initial = arrival ? checkIn : checkOut;
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value == null) return;
    setState(() {
      if (arrival) {
        checkIn = value;
        if (!checkOut.isAfter(value)) {
          checkOut = value.add(const Duration(days: 1));
        }
      } else if (value.isAfter(checkIn)) {
        checkOut = value;
      }
    });
  }

  Future<void> chooseGuests() async {
    var nextAdults = adults;
    var nextChildren = children;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('guests'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _TravelerCounter(
                  label: context.tr('adults'),
                  caption: context.tr('yearsAndOlder'),
                  value: nextAdults,
                  canRemove: nextAdults > 1,
                  canAdd: nextAdults + nextChildren < 9,
                  onRemove: () => setSheetState(() => nextAdults--),
                  onAdd: () => setSheetState(() => nextAdults++),
                ),
                const SizedBox(height: 8),
                _TravelerCounter(
                  label: context.tr('children'),
                  caption: context.tr('childrenAgeRange'),
                  value: nextChildren,
                  canRemove: nextChildren > 0,
                  canAdd: nextAdults + nextChildren < 9,
                  onRemove: () => setSheetState(() => nextChildren--),
                  onAdd: () => setSheetState(() => nextChildren++),
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: context.tr('done'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (apply == true) {
      setState(() {
        adults = nextAdults;
        children = nextChildren;
      });
    }
  }

  void search() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HotelResultsPage(
        search: HotelSearch(
          cityCode: city.code,
          checkIn: checkIn,
          checkOut: checkOut,
          adults: adults,
          children: children,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _TravelField(
        label: context.tr('destination'),
        value: _localizedCity(context, city.name),
        caption: _localizedCountry(context, city.country),
        onTap: editCity,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _TravelField(
              label: context.tr('checkIn'),
              value: _shortDate(checkIn),
              icon: Icons.calendar_month_outlined,
              onTap: () => pick(true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TravelField(
              label: context.tr('checkOut'),
              value: _shortDate(checkOut),
              icon: Icons.calendar_month_outlined,
              onTap: () => pick(false),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _TravelField(
        label: context.tr('guests'),
        value:
            '$adults ${context.tr('adults')}${children > 0 ? ', $children ${context.tr('children')}' : ''}',
        icon: Icons.people_outline,
        onTap: chooseGuests,
      ),
      const SizedBox(height: 10),
      AppButton(
        label: context.tr('searchHotels'),
        icon: Icons.search_rounded,
        onPressed: search,
      ),
    ],
  );
}
