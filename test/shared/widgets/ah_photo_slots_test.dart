import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/shared/widgets/ah_photo_slots.dart';

Widget _subject({ValueChanged<int>? onTapSlot}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SizedBox(
        // Narrower than 5 slots, so the row has to scroll.
        width: 200,
        child: AhPhotoSlots(count: 5, slots: const [], onTapSlot: onTapSlot),
      ),
    ),
  );
}

double _scrollOffset(WidgetTester tester) {
  final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
  return scrollable.position.pixels;
}

void main() {
  testWidgets('read-only slots still scroll horizontally', (tester) async {
    await tester.pumpWidget(_subject());

    await tester.drag(find.byType(AhPhotoSlots), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(_scrollOffset(tester), greaterThan(0));
  });

  testWidgets('read-only slots ignore taps', (tester) async {
    await tester.pumpWidget(_subject());

    final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
    expect(inkWell.onTap, isNull);
  });

  testWidgets('editable slots report the tapped index', (tester) async {
    int? tapped;
    await tester.pumpWidget(_subject(onTapSlot: (i) => tapped = i));

    await tester.tap(find.byType(InkWell).first);

    expect(tapped, 0);
  });

  testWidgets('filled slots show a remove button that reports the index', (
    tester,
  ) async {
    int? removed;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AhPhotoSlots(
            count: 3,
            slots: const [
              AhPhotoSlotData(status: AhPhotoSlotStatus.uploading),
              AhPhotoSlotData(status: AhPhotoSlotStatus.error),
            ],
            onTapSlot: (_) {},
            onRemoveSlot: (i) => removed = i,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('ah-photo-slot-remove-0')), findsOne);
    expect(find.byKey(const ValueKey('ah-photo-slot-remove-1')), findsOne);
    // Empty slots have nothing to remove.
    expect(find.byKey(const ValueKey('ah-photo-slot-remove-2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ah-photo-slot-remove-1')));
    expect(removed, 1);
  });

  testWidgets('no remove buttons without onRemoveSlot', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AhPhotoSlots(
            count: 1,
            slots: [AhPhotoSlotData(status: AhPhotoSlotStatus.uploading)],
            onTapSlot: null,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsNothing);
  });
}
