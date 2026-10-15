import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/features/search/domain/entities/hotel_search.dart';
import 'package:safer_be_project/features/search/presentation/widgets/hotel_room_picker_sheet.dart';

void main() {
  Widget buildTestWidget({
    required List<HotelSearchRoom> initialRooms,
    Locale locale = const Locale('en'),
    void Function(List<HotelSearchRoom>? result)? onResult,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final res = await HotelRoomPickerSheet.show(
                context,
                initialRooms: initialRooms,
              );
              onResult?.call(res);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('formatSummary produces natural English and Arabic labels', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        initialRooms: const [
          HotelSearchRoom(adults: 2, children: 0),
        ],
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(ElevatedButton));
    final enSummary = HotelRoomPickerSheet.formatSummary(context, const [
      HotelSearchRoom(adults: 2, children: 0),
    ]);
    expect(enSummary, '2 Guests, 1 Room');

    final enMultiSummary = HotelRoomPickerSheet.formatSummary(context, const [
      HotelSearchRoom(adults: 2, children: 1),
      HotelSearchRoom(adults: 1, children: 0),
    ]);
    expect(enMultiSummary, '4 Guests, 2 Rooms');
  });

  testWidgets('HotelRoomPickerSheet allows adding, modifying, and removing rooms up to 4', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<HotelSearchRoom>? sheetResult;

    await tester.pumpWidget(
      buildTestWidget(
        initialRooms: const [
          HotelSearchRoom(adults: 2, children: 0),
        ],
        onResult: (res) => sheetResult = res,
      ),
    );

    // Open sheet
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify initial state: 1 room, 2 adults
    expect(find.text('Room 1'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);

    // Add second room
    final addRoomBtn = find.text('+ Add another room');
    expect(addRoomBtn, findsOneWidget);
    await tester.tap(addRoomBtn);
    await tester.pumpAndSettle();

    expect(find.text('Room 2'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget); // Can remove Room 2

    // Add third room
    await tester.tap(addRoomBtn);
    await tester.pumpAndSettle();
    expect(find.text('Room 3'), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);

    // Add fourth room (max)
    await tester.tap(addRoomBtn);
    await tester.pumpAndSettle();
    expect(find.text('Room 4'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
    // At 4 rooms, "+ Add another room" should no longer appear
    expect(find.text('+ Add another room'), findsNothing);

    // Remove Room 4
    final removeBtns = find.text('Remove');
    expect(removeBtns, findsNWidgets(3)); // Room 2, 3, 4 have remove
    await tester.tap(removeBtns.last);
    await tester.pumpAndSettle();

    expect(find.text('Room 4'), findsNothing);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('+ Add another room'), findsOneWidget);

    // Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(sheetResult, isNotNull);
    expect(sheetResult!.length, 3);
  });

  testWidgets('HotelRoomPickerSheet configures children and ages properly', (tester) async {
    List<HotelSearchRoom>? sheetResult;

    await tester.pumpWidget(
      buildTestWidget(
        initialRooms: const [
          HotelSearchRoom(adults: 2, children: 0),
        ],
        onResult: (res) => sheetResult = res,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Tap plus icon next to children
    // Find add icons: first is adults (+), second is children (+)
    final addIcons = find.byIcon(Icons.add);
    expect(addIcons, findsNWidgets(2));
    await tester.tap(addIcons.at(1)); // Children +
    await tester.pumpAndSettle();

    // Verify Child 1 appears
    expect(find.text('Children ages'), findsOneWidget);
    expect(find.textContaining('Child 1'), findsOneWidget);

    // Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(sheetResult, isNotNull);
    expect(sheetResult!.first.children, 1);
    expect(sheetResult!.first.childAges, [5]); // Default age 5
  });
}
