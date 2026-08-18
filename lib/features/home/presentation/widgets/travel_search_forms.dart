part of 'travel_search_card.dart';

class _FlightForm extends StatefulWidget {
  const _FlightForm({super.key});

  @override
  State<_FlightForm> createState() => _FlightFormState();
}

class _FlightFormState extends State<_FlightForm> {
  Airport from = const Airport(
    code: 'RUH',
    name: 'King Khalid International',
    city: 'Riyadh',
  );
  Airport to = const Airport(
    code: 'DXB',
    name: 'Dubai International',
    city: 'Dubai',
  );
  DateTime date = DateTime.now().add(const Duration(days: 1));
  DateTime returnDate = DateTime.now().add(const Duration(days: 8));
  bool roundTrip = false;
  int adults = 1;
  int children = 0;
  int infants = 0;
  int cabinClass = 1;

  static const cabinNameKeys = {
    1: 'economy',
    2: 'businessCabin',
    3: 'firstClass',
    4: 'premiumEconomy',
  };

  String cabinName(BuildContext context, int value) =>
      context.tr(cabinNameKeys[value] ?? 'economy');

  Future<void> airport(bool origin) async {
    final value = await Navigator.push<Airport>(
      context,
      MaterialPageRoute(builder: (_) => const AirportPickerPage()),
    );
    if (value != null) setState(() => origin ? from = value : to = value);
  }

  Future<void> chooseDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null) {
      setState(() {
        date = value;
        if (!returnDate.isAfter(value)) {
          returnDate = value.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> chooseReturnDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: returnDate.isAfter(date)
          ? returnDate
          : date.add(const Duration(days: 1)),
      firstDate: date.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null) setState(() => returnDate = value);
  }

  Future<void> chooseTravelers() async {
    var nextAdults = adults;
    var nextChildren = children;
    var nextInfants = infants;
    var nextCabin = cabinClass;
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
                  context.tr('travelersAndCabin'),
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
                _TravelerCounter(
                  label: context.tr('children'),
                  caption: context.tr('childrenAgeRange'),
                  value: nextChildren,
                  canRemove: nextChildren > 0,
                  canAdd: nextAdults + nextChildren < 9,
                  onRemove: () => setSheetState(() => nextChildren--),
                  onAdd: () => setSheetState(() => nextChildren++),
                ),
                _TravelerCounter(
                  label: context.tr('infants'),
                  caption: context.tr('underTwoYears'),
                  value: nextInfants,
                  canRemove: nextInfants > 0,
                  canAdd: nextInfants < nextAdults,
                  onRemove: () => setSheetState(() => nextInfants--),
                  onAdd: () => setSheetState(() => nextInfants++),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: nextCabin,
                  decoration: InputDecoration(
                    labelText: context.tr('cabinClass'),
                  ),
                  items: cabinNameKeys.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(context.tr(entry.value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setSheetState(() => nextCabin = value ?? nextCabin),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.tr('apply')),
                  ),
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
        infants = nextInfants;
        cabinClass = nextCabin;
      });
    }
  }

  void search() {
    if (from.code == to.code) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('chooseDifferentAirports'))),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlightResultsPage(
          search: FlightSearch(
            origin: from.code,
            destination: to.code,
            departure: date,
            returnDate: roundTrip ? returnDate : null,
            adults: adults,
            children: children,
            infants: infants,
            cabinClass: cabinClass,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _FlightFormView(
    from: from,
    to: to,
    date: date,
    returnDate: returnDate,
    roundTrip: roundTrip,
    travelers: adults + children + infants,
    cabin: cabinName(context, cabinClass),
    chooseFrom: () => airport(true),
    chooseTo: () => airport(false),
    chooseDate: chooseDate,
    chooseReturnDate: chooseReturnDate,
    chooseTravelers: chooseTravelers,
    changeTripType: (value) => setState(() => roundTrip = value),
    swap: () => setState(() {
      final old = from;
      from = to;
      to = old;
    }),
    search: search,
  );
}

class _TravelerCounter extends StatelessWidget {
  const _TravelerCounter({
    required this.label,
    required this.caption,
    required this.value,
    required this.canRemove,
    required this.canAdd,
    required this.onRemove,
    required this.onAdd,
  });

  final String label;
  final String caption;
  final int value;
  final bool canRemove;
  final bool canAdd;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(caption, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: canRemove ? onRemove : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(width: 34, child: Text('$value', textAlign: TextAlign.center)),
        IconButton.filledTonal(
          onPressed: canAdd ? onAdd : null,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}

String _shortDate(DateTime value) =>
    '${value.day}/${value.month}/${value.year}';

String _localizedCity(BuildContext context, String city) => switch (city) {
  'Riyadh' => context.tr('riyadh'),
  'Dubai' => context.tr('dubai'),
  'Jeddah' => context.tr('jeddah'),
  _ => city,
};

String _localizedCountry(BuildContext context, String country) =>
    switch (country) {
      'Saudi Arabia' => context.tr('saudiArabia'),
      _ => country,
    };
