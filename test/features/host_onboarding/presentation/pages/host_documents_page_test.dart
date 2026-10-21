import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:host_mobile_app/core/di/document_compressor_providers.dart';
import 'package:host_mobile_app/core/di/document_picker_providers.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/files/document_compressor.dart';
import 'package:host_mobile_app/core/files/document_picker.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_type.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_upload_result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_type.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_verification_result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_verification_submission_draft.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_document_repository.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_verification_repository.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_document_api_providers.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_onboarding_progress_providers.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_type_controller.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_verification_api_providers.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/pages/host_documents_page.dart';
import 'package:host_mobile_app/shared/widgets/ah_button.dart';

import '../../../../support/fakes.dart';

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

/// Passes the path through untouched — avoids touching the real
/// filesystem for a fixture path that doesn't exist on disk.
class _FakeDocumentCompressor implements DocumentCompressor {
  const _FakeDocumentCompressor();

  @override
  Future<String> compress(String path, String fileName) async => path;
}

/// Resolves every upload instantly with success, so widget tests don't
/// make real network calls or race the background upload.
class _FakeHostDocumentRepository implements HostDocumentRepository {
  const _FakeHostDocumentRepository();

  @override
  Future<Result<HostDocumentUploadResult>> uploadDocument({
    required HostDocumentType documentType,
    required String filePath,
    required String fileName,
  }) async {
    return const Ok(
      HostDocumentUploadResult(documentId: 'test-doc', status: 'UPLOADED'),
    );
  }
}

class _FakeHostVerificationRepository implements HostVerificationRepository {
  _FakeHostVerificationRepository(this._result);
  final Result<HostVerificationResult> _result;

  @override
  Future<Result<HostVerificationResult>> submit(
    HostVerificationSubmissionDraft draft,
  ) async => _result;
}

void main() {
  Widget buildSubject(
    HostType hostType, {
    DocumentPickerResult? pickerResult = const DocumentPickerResult(
      fileName: 'document.pdf',
      path: 'document.pdf',
    ),
    Result<HostVerificationResult> verificationResult = const Ok(
      HostVerificationResult(message: 'Verification submitted for review'),
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
        documentCompressorProvider.overrideWithValue(
          const _FakeDocumentCompressor(),
        ),
        hostDocumentRepositoryProvider.overrideWithValue(
          const _FakeHostDocumentRepository(),
        ),
        hostVerificationRepositoryProvider.overrideWithValue(
          _FakeHostVerificationRepository(verificationResult),
        ),
        hostOnboardingProgressRepositoryProvider.overrideWithValue(
          FakeHostOnboardingProgressRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const HostDocumentsPage(),
      ),
    );
  }

  Widget buildRoutedSubject(
    HostType hostType, {
    DocumentPickerResult? pickerResult = const DocumentPickerResult(
      fileName: 'document.pdf',
      path: 'document.pdf',
    ),
    Result<HostVerificationResult> verificationResult = const Ok(
      HostVerificationResult(message: 'Verification submitted for review'),
    ),
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HostDocumentsPage(),
        ),
        GoRoute(
          path: '/host/signup/host-type/documents/verification',
          builder: (context, state) =>
              const Scaffold(body: Text('Verification page')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        hostTypeControllerProvider.overrideWith(
          () => _FixedHostTypeController(hostType),
        ),
        documentPickerProvider.overrideWithValue(
          _FakeDocumentPicker(pickerResult),
        ),
        documentCompressorProvider.overrideWithValue(
          const _FakeDocumentCompressor(),
        ),
        hostDocumentRepositoryProvider.overrideWithValue(
          const _FakeHostDocumentRepository(),
        ),
        hostVerificationRepositoryProvider.overrideWithValue(
          _FakeHostVerificationRepository(verificationResult),
        ),
        hostOnboardingProgressRepositoryProvider.overrideWithValue(
          FakeHostOnboardingProgressRepository(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets('a non-venue host does not see venue fields', (tester) async {
    await tester.pumpWidget(buildSubject(HostType.club));

    expect(find.text('Verification documents'), findsOneWidget);
    expect(find.text('UPI ID for payouts'), findsOneWidget);
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
      expect(find.text('FSSAI valid from'), findsOneWidget);
      expect(find.text('FSSAI valid to'), findsOneWidget);
      expect(find.text('Excise valid from'), findsOneWidget);
      expect(find.text('Excise valid to'), findsOneWidget);
    },
  );

  testWidgets('tapping a document row picks a file and shows it as Selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        HostType.club,
        pickerResult: const DocumentPickerResult(
          fileName: 'pan-card.pdf',
          path: 'pan-card.pdf',
        ),
      ),
    );

    await tester.tap(find.text('PAN card'));
    await tester.pumpAndSettle();

    expect(find.text('Uploaded'), findsOneWidget);
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
      find.widgetWithText(AhButton, 'Submit for review'),
    );
    await tester.tap(find.widgetWithText(AhButton, 'Submit for review'));
    await tester.pump();

    expect(find.text('Required when serving alcohol'), findsWidgets);
  });

  testWidgets(
    'submitting a club with valid UPI and required documents advances to '
    'H-04 · Verification',
    (tester) async {
      await tester.pumpWidget(buildRoutedSubject(HostType.club));

      await tester.enterText(
        find.widgetWithText(TextField, 'business@upi'),
        'business@upi',
      );
      await tester.tap(find.text('Business registration or organiser ID'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PAN card'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AhButton, 'Submit for review'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid UPI ID'), findsNothing);
      expect(find.text('Upload required'), findsNothing);
      expect(find.text('Verification page'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the submit error and stays on the page when submit-verification '
    'fails',
    (tester) async {
      await tester.pumpWidget(
        buildRoutedSubject(
          HostType.club,
          verificationResult: const Err(
            NetworkFailure(message: 'Submission failed.'),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'business@upi'),
        'business@upi',
      );
      await tester.tap(find.text('Business registration or organiser ID'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PAN card'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AhButton, 'Submit for review'));
      await tester.pumpAndSettle();

      expect(find.text('Submission failed.'), findsOneWidget);
      expect(find.text('Verification page'), findsNothing);
    },
  );
}
