part of 'travel_search_card.dart';

class _SearchTabs extends StatelessWidget {
  const _SearchTabs({required this.selected, required this.onChanged});

  final SearchKind selected;
  final ValueChanged<SearchKind> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: SearchKind.values.map((kind) {
        final active = selected == kind;
        final data = switch (kind) {
          SearchKind.flight => (Icons.flight_takeoff_rounded, 'flights'),
          SearchKind.hotel => (Icons.hotel_rounded, 'hotels'),
          SearchKind.transfer => (
            Icons.directions_car_filled_rounded,
            'transfers',
          ),
        };
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(kind),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
              decoration: BoxDecoration(
                color: active ? AppColors.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    data.$1,
                    size: 17,
                    color: active ? Colors.white : AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      context.tr(data.$2),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
