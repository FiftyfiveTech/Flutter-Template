import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/di/document_picker_providers.dart';
import 'package:host_mobile_app/core/files/document_picker.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_type.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_type_controller.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/pages/host_documents_page.dart';

class _FixedHostTypeController extends HostTypeController {
  _FixedHostTypeController(this._initial);
  final HostType _initial;

  @override
  HostType? build() => _initial;
}

class _FakeDocumentPicker implements DocumentPicker {
  const _FakeDocumentPicker(this._result);
  final DocumentPickerResult? _result;

  @override
  Future<DocumentPickerResult?> pickFile({
    required List<String> allowedExtensions,
  }) async => _result;
}

void main() {
  Widget buildSubject(
    HostType hostType, {
    DocumentPickerResult? pickerResult = const DocumentPickerResult(
      fileName: 'document.pdf',
    ),
  }) {
    return ProviderScope(
      overrides: [
        hostTypeControllerProvider.overrideWith(
          () => _FixedHostTypeController(hostType),
        ),
        documentPickerProvider.overrideWithValue(
          _FakeDocumentPicker(pickerResult),
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const HostDocumentsPage()),
    );
  }

  testWidgets('a non-venue host sees the scoping banner, not venue fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(HostType.club));

    expect(find.text('Verification documents'), findsOneWidget);
    expect(find.text('UPI ID for payouts'), findsOneWidget);
    expect(
      find.textContaining('skip the address proof, FSSAI and excise'),
      findsOneWidget,
    );
    expect(find.text('Premises address proof'), findsNothing);
  });

  testWidgets(
    'a venue host sees every additional document field, regardless of the '
    'food/alcohol switches',
    (tester) async {
      await tester.pumpWidget(buildSubject(HostType.venue));

      expect(find.text('Premises address proof'), findsOneWidget);
      expect(find.text('We serve food'), findsOneWidget);
      expect(find.text('We serve alcohol'), findsOneWidget);
      expect(find.text('FSSAI registration'), findsOneWidget);
      expect(find.text('Excise licence'), findsOneWidget);
      expect(find.text('Licence valid from'), findsOneWidget);
      expect(find.text('Licence valid to'), findsOneWidget);
    },
  );

  testWidgets('tapping a document row picks a file and shows it as Selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        HostType.club,
        pickerResult: const DocumentPickerResult(fileName: 'pan-card.pdf'),
      ),
    );

    await tester.tap(find.text('PAN card'));
    await tester.pumpAndSettle();

    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('pan-card.pdf'), findsOneWidget);
  });

  testWidgets('submitting a venue with alcohol but no licence dates errors', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(HostType.venue));

    await tester.enterText(
      find.widgetWithText(TextField, 'business@upi'),
      'business@upi',
    );
    await tester.ensureVisible(find.text('We serve alcohol'));
    await tester.tap(find.text('We serve alcohol'));
    await tester.pump();
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Submit for review'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit for review'));
    await tester.pump();

    expect(find.text('Required when serving alcohol'), findsWidgets);
  });

  testWidgets(
    'submitting a club with valid UPI and required documents advances',
    (tester) async {
      await tester.pumpWidget(buildSubject(HostType.club));

      await tester.enterText(
        find.widgetWithText(TextField, 'business@upi'),
        'business@upi',
      );
      await tester.tap(find.text('Business registration or organiser ID'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PAN card'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Submit for review'),
      );
      await tester.pump();

      expect(find.text('Enter a valid UPI ID'), findsNothing);
      expect(find.text('Upload required'), findsNothing);
      expect(find.text('Verification — coming soon'), findsOneWidget);
    },
  );
}
