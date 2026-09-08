import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/pages/host_type_page.dart';

void main() {
  Widget buildSubject() {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.dark, home: const HostTypePage()),
    );
  }

  testWidgets('renders all four host type options and a Continue button', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('What kind of host are you'), findsOneWidget);
    expect(find.text('Club'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Venue'), findsOneWidget);
    expect(find.text('Individual operator'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
  });

  testWidgets('shows an error when Continue is tapped with no selection', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();

    expect(find.text('Choose a host type to continue'), findsOneWidget);
  });

  testWidgets('advances once a host type is selected', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('Venue'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();

    expect(find.text('Choose a host type to continue'), findsNothing);
    expect(find.text('Documents — coming soon'), findsOneWidget);
  });
}
