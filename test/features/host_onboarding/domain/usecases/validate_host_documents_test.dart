import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_selection.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_type.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_documents_draft.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_type.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/usecases/validate_host_documents.dart';

const _picked = HostDocumentSelection(fileName: 'file.pdf');

void main() {
  const useCase = ValidateHostDocumentsUseCase();

  const requiredForEveryHost = {
    HostDocumentType.businessRegistration: _picked,
    HostDocumentType.panCard: _picked,
  };

  const validNonVenueDraft = HostDocumentsDraft(
    upiId: 'business@upi',
    documents: requiredForEveryHost,
  );

  const validVenueDraft = HostDocumentsDraft(
    upiId: 'business@upi',
    documents: {
      ...requiredForEveryHost,
      HostDocumentType.addressProof: _picked,
    },
  );

  test('returns Ok for a non-venue host with a valid UPI ID and documents', () {
    final result = useCase(validNonVenueDraft, hostType: HostType.club);

    expect(result, isA<Ok<HostDocumentsDraft>>());
  });

  test('flags an invalid UPI ID', () {
    final result = useCase(
      validNonVenueDraft.copyWith(upiId: 'not-a-upi'),
      hostType: HostType.club,
    );

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostDocumentsValidationFailure).fieldErrors;
        expect(fieldErrors, containsPair('upiId', isNotEmpty));
      },
    );
  });

  test('flags a missing required document', () {
    final result = useCase(
      const HostDocumentsDraft(upiId: 'business@upi'),
      hostType: HostType.club,
    );

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostDocumentsValidationFailure).fieldErrors;
        expect(
          fieldErrors,
          containsPair(HostDocumentType.businessRegistration.name, isNotEmpty),
        );
        expect(
          fieldErrors,
          containsPair(HostDocumentType.panCard.name, isNotEmpty),
        );
      },
    );
  });

  test('requires address proof for a venue but not a club', () {
    final result = useCase(validNonVenueDraft, hostType: HostType.venue);

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostDocumentsValidationFailure).fieldErrors;
        expect(
          fieldErrors,
          containsPair(HostDocumentType.addressProof.name, isNotEmpty),
        );
      },
    );
  });

  test(
    'does not require FSSAI/excise/licence dates for a venue that serves neither',
    () {
      final result = useCase(validVenueDraft, hostType: HostType.venue);

      expect(result, isA<Ok<HostDocumentsDraft>>());
    },
  );

  test('requires FSSAI registration once a venue serves food', () {
    final result = useCase(
      validVenueDraft.copyWith(servesFood: true),
      hostType: HostType.venue,
    );

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostDocumentsValidationFailure).fieldErrors;
        expect(
          fieldErrors,
          containsPair(HostDocumentType.fssaiRegistration.name, isNotEmpty),
        );
      },
    );
  });

  test(
    'requires excise licence and licence dates once a venue serves alcohol',
    () {
      final result = useCase(
        validVenueDraft.copyWith(servesAlcohol: true),
        hostType: HostType.venue,
      );

      result.when(
        ok: (_) => fail('expected Err'),
        err: (failure) {
          final fieldErrors =
              (failure as HostDocumentsValidationFailure).fieldErrors;
          expect(
            fieldErrors,
            containsPair(HostDocumentType.exciseLicence.name, isNotEmpty),
          );
          expect(fieldErrors, containsPair('licenceValidFrom', isNotEmpty));
          expect(fieldErrors, containsPair('licenceValidTo', isNotEmpty));
        },
      );
    },
  );

  test('flags a licence valid-to date that is not after valid-from', () {
    final result = useCase(
      validVenueDraft.copyWith(
        servesAlcohol: true,
        documents: {
          ...validVenueDraft.documents,
          HostDocumentType.exciseLicence: _picked,
        },
        licenceValidFrom: DateTime(2026, 4, 1),
        licenceValidTo: DateTime(2026, 1, 1),
      ),
      hostType: HostType.venue,
    );

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostDocumentsValidationFailure).fieldErrors;
        expect(fieldErrors, containsPair('licenceValidTo', isNotEmpty));
      },
    );
  });

  test('accepts a venue serving alcohol with a valid licence window', () {
    final result = useCase(
      validVenueDraft.copyWith(
        servesAlcohol: true,
        documents: {
          ...validVenueDraft.documents,
          HostDocumentType.exciseLicence: _picked,
        },
        licenceValidFrom: DateTime(2026, 4, 1),
        licenceValidTo: DateTime(2027, 3, 31),
      ),
      hostType: HostType.venue,
    );

    expect(result, isA<Ok<HostDocumentsDraft>>());
  });
}
