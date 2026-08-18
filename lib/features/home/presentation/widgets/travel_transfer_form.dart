part of 'travel_search_card.dart';

class _TransferForm extends StatelessWidget {
  const _TransferForm({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _TravelField(
        label: context.tr('serviceType'),
        value: context.tr('airportPickup'),
        caption: context.tr('comingSoon'),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _TravelField(label: context.tr('airport'), value: 'RUH'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TravelField(
              label: context.tr('destination'),
              value: 'KAFD',
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      AppButton(
        label: context.tr('bookTransfer'),
        icon: Icons.arrow_forward_rounded,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('transfersUnavailable'))),
        ),
      ),
    ],
  );
}
