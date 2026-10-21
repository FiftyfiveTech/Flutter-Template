import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/shared/widgets/ah_async_search_field.dart';
import 'package:host_mobile_app/shared/widgets/ah_date_time_field.dart';

const _options = ['Dinner', 'Tasting', 'Board games'];

Widget _subject({
  required String value,
  required ValueChanged<String> onSelected,
  bool clearOnSelect = false,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: AhAsyncSearchField<String>(
        label: 'Format',
        value: value,
        search: (query) async => _options
            .where((o) => o.toLowerCase().contains(query.toLowerCase()))
            .toList(),
        displayStringForOption: (o) => o,
        onSelected: onSelected,
        debounce: Duration.zero,
        searchOnEmptyQuery: true,
        clearOnSelect: clearOnSelect,
      ),
    ),
  );
}

void main() {
  testWidgets('filters local options as you type and reports the pick', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(_subject(value: '', onSelected: (v) => picked = v));

    await tester.enterText(find.byType(TextField), 'tast');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Dinner'), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, 'Tasting'));
    await tester.pumpAndSettle();

    expect(picked, 'Tasting');
    expect(find.widgetWithText(TextField, 'Tasting'), findsOneWidget);
  });

  testWidgets('clearOnSelect empties the field after each pick', (
    tester,
  ) async {
    final picked = <String>[];
    await tester.pumpWidget(
      _subject(value: '', onSelected: picked.add, clearOnSelect: true),
    );

    await tester.enterText(find.byType(TextField), 'din');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Dinner'));
    await tester.pumpAndSettle();

    expect(picked, ['Dinner']);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('shows a value set after the field was built', (tester) async {
    await tester.pumpWidget(_subject(value: '', onSelected: (_) {}));
    await tester.pumpWidget(_subject(value: 'Dinner', onSelected: (_) {}));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Dinner'), findsOneWidget);
  });

  testWidgets('closing a date picker after a pick does not reopen the list', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              AhAsyncSearchField<String>(
                label: 'Format',
                value: '',
                search: (query) async => _options,
                displayStringForOption: (o) => o,
                onSelected: (_) {},
                debounce: Duration.zero,
                searchOnEmptyQuery: true,
              ),
              AhDateTimeField(
                label: 'Start date & time',
                value: null,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Dinner'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AhDateTimeField),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Tasting'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isFalse);
  });
}
