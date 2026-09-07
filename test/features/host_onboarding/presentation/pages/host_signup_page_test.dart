import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/pages/host_signup_page.dart';

void main() {
  Widget buildSubject() {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.dark, home: const HostSignupPage()),
    );
  }

  testWidgets('renders the four signup fields and a Continue button', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Host signup'), findsOneWidget);
    expect(find.text('Business or organiser name'), findsOneWidget);
    expect(find.text('Contact phone'), findsOneWidget);
    expect(find.text('Contact email'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
  });

  testWidgets('shows field errors when Continue is tapped with empty fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();

    expect(find.text('Enter a business or organiser name'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });
}
