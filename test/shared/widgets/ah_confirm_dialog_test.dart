import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/shared/widgets/ah_confirm_dialog.dart';

void main() {
  /// Opens the dialog; the returned list receives its result once closed.
  Future<List<bool>> openDialog(WidgetTester tester) async {
    final results = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await showAhConfirmDialog(
                  context,
                  title: 'Delete this draft?',
                  message: "This can't be undone.",
                  confirmLabel: 'Delete draft',
                  cancelLabel: 'Keep draft',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this draft?'), findsOneWidget);
    expect(find.text("This can't be undone."), findsOneWidget);
    return results;
  }

  testWidgets('resolves true when the action is confirmed', (tester) async {
    final results = await openDialog(tester);

    await tester.tap(find.text('Delete draft'));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(find.text('Delete this draft?'), findsNothing);
  });

  testWidgets('resolves false when cancelled', (tester) async {
    final results = await openDialog(tester);

    await tester.tap(find.text('Keep draft'));
    await tester.pumpAndSettle();

    expect(results, [false]);
  });

  testWidgets('resolves false when dismissed by tapping outside', (
    tester,
  ) async {
    final results = await openDialog(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(results, [false]);
  });
}
