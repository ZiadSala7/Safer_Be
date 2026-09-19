import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../search/domain/entities/airport.dart';
import '../../../search/domain/entities/flight_search.dart';
import '../../../search/domain/entities/hotel_search.dart';
import '../../../search/domain/entities/travel_city.dart';
import '../../../search/presentation/pages/airport_picker_page.dart';
import '../../../search/presentation/pages/flight_results_page.dart';
import '../../../search/presentation/pages/hotel_results_page.dart';
import '../../../search/presentation/pages/city_picker_page.dart';

part 'travel_search_forms.dart';
part 'flight_form_view.dart';
part 'travel_stay_forms.dart';
part 'travel_transfer_form.dart';
part 'travel_search_tabs.dart';
part 'travel_field.dart';

enum SearchKind { flight, hotel, transfer }

class TravelSearchCard extends StatefulWidget {
  const TravelSearchCard({super.key});

  @override
  State<TravelSearchCard> createState() => _TravelSearchCardState();
}

class _TravelSearchCardState extends State<TravelSearchCard> {
  SearchKind selected = SearchKind.flight;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    elevation: 10,
    shadowColor: Colors.black26,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _SearchTabs(
            selected: selected,
            onChanged: (value) => setState(() => selected = value),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (selected) {
              SearchKind.flight => const _FlightForm(key: ValueKey('flight')),
              SearchKind.hotel => const _HotelForm(key: ValueKey('hotel')),
              SearchKind.transfer => const _TransferForm(
                key: ValueKey('transfer'),
              ),
            },
          ),
        ],
      ),
    ),
  );
}
