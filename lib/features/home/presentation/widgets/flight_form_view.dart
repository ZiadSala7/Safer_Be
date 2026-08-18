part of 'travel_search_card.dart';

class _FlightFormView extends StatelessWidget {
  const _FlightFormView({
    required this.from,
    required this.to,
    required this.date,
    required this.returnDate,
    required this.roundTrip,
    required this.travelers,
    required this.cabin,
    required this.chooseFrom,
    required this.chooseTo,
    required this.chooseDate,
    required this.chooseReturnDate,
    required this.chooseTravelers,
    required this.changeTripType,
    required this.swap,
    required this.search,
  });

  final Airport from;
  final Airport to;
  final DateTime date;
  final DateTime returnDate;
  final bool roundTrip;
  final int travelers;
  final String cabin;
  final VoidCallback chooseFrom;
  final VoidCallback chooseTo;
  final VoidCallback chooseDate;
  final VoidCallback chooseReturnDate;
  final VoidCallback chooseTravelers;
  final ValueChanged<bool> changeTripType;
  final VoidCallback swap;
  final VoidCallback search;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(context.tr('oneWay'))),
            ButtonSegment(value: true, label: Text(context.tr('roundTrip'))),
          ],
          selected: {roundTrip},
          showSelectedIcon: false,
          onSelectionChanged: (value) => changeTripType(value.first),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _TravelField(
              label: context.tr('from'),
              value: from.code,
              caption: _localizedCity(context, from.city),
              onTap: chooseFrom,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: IconButton.filledTonal(
              onPressed: swap,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            ),
          ),
          Expanded(
            child: _TravelField(
              label: context.tr('to'),
              value: to.code,
              caption: _localizedCity(context, to.city),
              onTap: chooseTo,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _TravelField(
              label: context.tr('departure'),
              value: _shortDate(date),
              icon: Icons.calendar_month_outlined,
              onTap: chooseDate,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TravelField(
              label: roundTrip ? context.tr('return') : context.tr('travelers'),
              value: roundTrip
                  ? _shortDate(returnDate)
                  : '$travelers ${context.tr('traveler')}',
              caption: roundTrip ? null : cabin,
              icon: roundTrip
                  ? Icons.calendar_month_outlined
                  : Icons.person_outline_rounded,
              onTap: roundTrip ? chooseReturnDate : chooseTravelers,
            ),
          ),
        ],
      ),
      if (roundTrip) ...[
        const SizedBox(height: 8),
        _TravelField(
          label: context.tr('travelers'),
          value: '$travelers ${context.tr('traveler')}',
          caption: cabin,
          icon: Icons.person_outline_rounded,
          onTap: chooseTravelers,
        ),
      ],
      const SizedBox(height: 10),
      AppButton(
        label: context.tr('searchFlights'),
        icon: Icons.search_rounded,
        onPressed: search,
      ),
    ],
  );
}
