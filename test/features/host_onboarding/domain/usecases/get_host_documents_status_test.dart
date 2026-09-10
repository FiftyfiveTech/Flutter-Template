import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_status.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_type.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_verification_status.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_document_status_repository.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/usecases/get_host_documents_status.dart';

class _FakeHostDocumentStatusRepository
    implements HostDocumentStatusRepository {
  _FakeHostDocumentStatusRepository(this._result);
  final Result<List<HostDocumentStatus>> _result;

  @override
  Future<Result<List<HostDocumentStatus>>> getDocumentsStatus() async =>
      _result;
}

void main() {
  test('returns the repository result unchanged', () async {
    const documents = [
      HostDocumentStatus(
        docType: HostDocumentType.panCard,
        status: HostDocumentVerificationStatus.verified,
      ),
    ];
    final repository = _FakeHostDocumentStatusRepository(const Ok(documents));
    final useCase = GetHostDocumentsStatusUseCase(repository);

    final actual = await useCase();

    actual.when(
      ok: (value) => expect(value, documents),
      err: (_) => fail('expected Ok'),
    );
  });

  test('surfaces a repository failure unchanged', () async {
    const failure = NetworkFailure(message: "Couldn't load status.");
    final repository = _FakeHostDocumentStatusRepository(const Err(failure));
    final useCase = GetHostDocumentsStatusUseCase(repository);

    final actual = await useCase();

    actual.when(
      ok: (_) => fail('expected Err'),
      err: (value) => expect(value.message, "Couldn't load status."),
    );
  });
}
