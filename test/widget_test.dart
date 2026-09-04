import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:after_hours/core/theme/app_theme.dart';
import 'package:after_hours/features/sample_counter/presentation/pages/counter_page.dart';
import 'package:after_hours/features/sample_counter/presentation/controllers/counter_controller.dart';
import 'package:after_hours/features/sample_counter/domain/entities/counter_record.dart';

class FakeCounterController extends CounterController {
  FakeCounterController(this.initialRecord);
  final CounterRecord initialRecord;

  @override
  Future<CounterRecord> build() async {
    return initialRecord;
  }
}

void main() {
  testWidgets('CounterPage renders count value and increment button', (WidgetTester tester) async {
    final record = CounterRecord(id: 1, value: 12, updatedAt: DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          counterControllerProvider.overrideWith(() => FakeCounterController(record)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CounterPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify counter value is rendered
    expect(find.text('12'), findsOneWidget);
    // Verify button is rendered
    expect(find.text('Increment Count'), findsOneWidget);
  });
}
