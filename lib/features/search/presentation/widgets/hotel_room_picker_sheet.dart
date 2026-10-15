import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/hotel_search.dart';

class HotelRoomPickerSheet extends StatefulWidget {
  const HotelRoomPickerSheet({
    super.key,
    required this.initialRooms,
  });

  final List<HotelSearchRoom> initialRooms;

  static const int maxRooms = 4;
  static const int maxAdultsPerRoom = 8;
  static const int maxChildrenPerRoom = 6;
  static const int defaultChildAge = 5;

  static Future<List<HotelSearchRoom>?> show(
    BuildContext context, {
    required List<HotelSearchRoom> initialRooms,
  }) {
    return showModalBottomSheet<List<HotelSearchRoom>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => HotelRoomPickerSheet(initialRooms: initialRooms),
    );
  }

  static String formatSummary(BuildContext context, List<HotelSearchRoom> rooms) {
    final effectiveRooms = rooms.isEmpty ? [const HotelSearchRoom()] : rooms;
    final totalAdults = effectiveRooms.fold<int>(0, (sum, r) => sum + r.adults);
    final totalChildren = effectiveRooms.fold<int>(0, (sum, r) => sum + r.children);
    final totalGuests = totalAdults + totalChildren;
    final roomCount = effectiveRooms.length;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (isArabic) {
      final guestPart = totalGuests == 1
          ? 'ضيف واحد'
          : totalGuests == 2
              ? 'ضيفان'
              : totalGuests <= 10
                  ? '$totalGuests ضيوف'
                  : '$totalGuests ضيف';

      final roomPart = roomCount == 1
          ? 'غرفة واحدة'
          : roomCount == 2
              ? 'غرفتان'
              : roomCount <= 10
                  ? '$roomCount غرف'
                  : '$roomCount غرفة';

      return '$guestPart، $roomPart';
    }

    final guestLabel =
        totalGuests == 1 ? context.tr('singleGuest') : context.tr('multipleGuests');
    final roomLabel =
        roomCount == 1 ? context.tr('singleRoom') : context.tr('multipleRooms');

    return '$totalGuests $guestLabel, $roomCount $roomLabel';
  }

  @override
  State<HotelRoomPickerSheet> createState() => _HotelRoomPickerSheetState();
}

class _HotelRoomPickerSheetState extends State<HotelRoomPickerSheet> {
  late List<HotelSearchRoom> _rooms;

  @override
  void initState() {
    super.initState();
    if (widget.initialRooms.isEmpty) {
      _rooms = [const HotelSearchRoom(adults: 2, children: 0)];
    } else {
      _rooms = widget.initialRooms
          .map((r) => r.copyWith(childAges: _syncChildAges(r.childAges, r.children)))
          .toList();
    }
  }

  List<int> _syncChildAges(List<int> currentAges, int targetCount) {
    if (currentAges.length == targetCount) return currentAges;
    if (currentAges.length > targetCount) {
      return currentAges.sublist(0, targetCount);
    }
    return [
      ...currentAges,
      ...List.generate(
        targetCount - currentAges.length,
        (_) => HotelRoomPickerSheet.defaultChildAge,
      ),
    ];
  }

  void _addRoom() {
    if (_rooms.length >= HotelRoomPickerSheet.maxRooms) return;
    setState(() {
      _rooms.add(const HotelSearchRoom(adults: 1, children: 0));
    });
  }

  void _removeRoom(int index) {
    if (_rooms.length <= 1) return;
    setState(() {
      _rooms.removeAt(index);
    });
  }

  void _updateAdults(int index, int newAdults) {
    if (newAdults < 1 || newAdults > HotelRoomPickerSheet.maxAdultsPerRoom) return;
    setState(() {
      _rooms[index] = _rooms[index].copyWith(adults: newAdults);
    });
  }

  void _updateChildren(int index, int newChildren) {
    if (newChildren < 0 || newChildren > HotelRoomPickerSheet.maxChildrenPerRoom) return;
    setState(() {
      final updatedAges = _syncChildAges(_rooms[index].childAges, newChildren);
      _rooms[index] = _rooms[index].copyWith(
        children: newChildren,
        childAges: updatedAges,
      );
    });
  }

  void _updateChildAge(int roomIndex, int childIndex, int age) {
    setState(() {
      final ages = List<int>.from(_rooms[roomIndex].childAges);
      if (childIndex < ages.length) {
        ages[childIndex] = age;
        _rooms[roomIndex] = _rooms[roomIndex].copyWith(childAges: ages);
      }
    });
  }

  String _formatChildAgeLabel(BuildContext context, int age) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (age < 1) {
      return context.tr('childAgeInfant');
    }
    if (isArabic) {
      if (age == 1) return 'سنة واحدة';
      if (age == 2) return 'سنتان';
      if (age <= 10) return '$age سنوات';
      return '$age سنة';
    }
    return age == 1 ? '1 year' : '$age years';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.teal : AppColors.orange;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Sheet Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('guestsAndRooms'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('travellers'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 16, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '${_rooms.length}/${HotelRoomPickerSheet.maxRooms}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Rooms List
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _rooms.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final room = _rooms[index];
                return _RoomCard(
                  roomNumber: index + 1,
                  room: room,
                  canRemove: _rooms.length > 1 && index > 0,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onRemove: () => _removeRoom(index),
                  onAdultsChanged: (val) => _updateAdults(index, val),
                  onChildrenChanged: (val) => _updateChildren(index, val),
                  onChildAgeChanged: (childIndex, age) =>
                      _updateChildAge(index, childIndex, age),
                  formatAgeLabel: (age) => _formatChildAgeLabel(context, age),
                );
              },
            ),
          ),

          // Bottom Action Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_rooms.length < HotelRoomPickerSheet.maxRooms)
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(
                            color: primaryColor.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _addRoom,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          context.tr('addAnotherRoom'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (_rooms.length < HotelRoomPickerSheet.maxRooms)
                    const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: AppButton(
                      label: context.tr('done'),
                      onPressed: () => Navigator.pop(context, _rooms),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.roomNumber,
    required this.room,
    required this.canRemove,
    required this.primaryColor,
    required this.isDark,
    required this.onRemove,
    required this.onAdultsChanged,
    required this.onChildrenChanged,
    required this.onChildAgeChanged,
    required this.formatAgeLabel,
  });

  final int roomNumber;
  final HotelSearchRoom room;
  final bool canRemove;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onRemove;
  final ValueChanged<int> onAdultsChanged;
  final ValueChanged<int> onChildrenChanged;
  final void Function(int childIndex, int age) onChildAgeChanged;
  final String Function(int age) formatAgeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hotel_rounded,
                  size: 16,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${context.tr('roomNumber')} $roomNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (canRemove)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(
                    context.tr('removeRoom'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Adults Row
          _RoomStepperRow(
            label: context.tr('adults'),
            caption: context.tr('adultsHint'),
            value: room.adults,
            minValue: 1,
            maxValue: HotelRoomPickerSheet.maxAdultsPerRoom,
            onChanged: onAdultsChanged,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 6),

          // Children Row
          _RoomStepperRow(
            label: context.tr('children'),
            caption: context.tr('childrenHint'),
            value: room.children,
            minValue: 0,
            maxValue: HotelRoomPickerSheet.maxChildrenPerRoom,
            onChanged: onChildrenChanged,
            primaryColor: primaryColor,
          ),

          // Children Ages Dropdowns
          if (room.children > 0) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.child_care_rounded,
                    size: 15,
                    color: primaryColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('childrenAges'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(room.children, (childIdx) {
                final currentAge = childIdx < room.childAges.length
                    ? room.childAges[childIdx]
                    : HotelRoomPickerSheet.defaultChildAge;

                return Container(
                  width: 145,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F1E36)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${context.tr('childAge')} ${childIdx + 1}:',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: currentAge,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.navy,
                            ),
                            items: List.generate(18, (age) {
                              return DropdownMenuItem<int>(
                                value: age,
                                child: Text(
                                  formatAgeLabel(age),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                              );
                            }),
                            onChanged: (newAge) {
                              if (newAge != null) {
                                onChildAgeChanged(childIdx, newAge);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomStepperRow extends StatelessWidget {
  const _RoomStepperRow({
    required this.label,
    required this.caption,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    required this.primaryColor,
  });

  final String label;
  final String caption;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final canMinus = value > minValue;
    final canPlus = value < maxValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  caption,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          IconButton.outlined(
            style: IconButton.styleFrom(
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
              side: BorderSide(
                color: canMinus ? primaryColor.withValues(alpha: 0.5) : Colors.grey.shade300,
              ),
            ),
            onPressed: canMinus ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 16),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
              backgroundColor: canPlus ? primaryColor.withValues(alpha: 0.15) : null,
              foregroundColor: canPlus ? primaryColor : null,
            ),
            onPressed: canPlus ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    );
  }
}
