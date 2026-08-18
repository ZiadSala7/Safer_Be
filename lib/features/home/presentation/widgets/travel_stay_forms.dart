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

  void search() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HotelResultsPage(
        search: HotelSearch(
          cityCode: city.code,
          checkIn: checkIn,
          checkOut: checkOut,
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
      const SizedBox(height: 10),
      AppButton(
        label: context.tr('searchHotels'),
        icon: Icons.search_rounded,
        onPressed: search,
      ),
    ],
  );
}
