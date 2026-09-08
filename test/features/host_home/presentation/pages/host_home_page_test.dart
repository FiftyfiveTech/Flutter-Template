import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_home/presentation/pages/host_home_page.dart';

void main() {
  Widget buildSubject() {
    return MaterialApp(theme: AppTheme.dark, home: const HostHomePage());
  }

  testWidgets('renders the three nav stubs', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Night ops'), findsOneWidget);
    expect(find.text('Payouts'), findsOneWidget);
  });

  testWidgets('tapping a nav card shows a coming-soon message', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('Events'));
    await tester.pump();

    expect(find.text('Events — coming soon'), findsOneWidget);
  });
}
