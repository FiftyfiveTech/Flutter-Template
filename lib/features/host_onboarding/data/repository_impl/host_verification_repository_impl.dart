import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_verification_result.dart';
import '../../domain/entities/host_verification_submission_draft.dart';
import '../../domain/repositories/host_verification_repository.dart';
import '../datasources/host_verification_remote_datasource.dart';
import '../models/host_verification_submission_dto.dart';

class HostVerificationRepositoryImpl implements HostVerificationRepository {
  const HostVerificationRepositoryImpl(this._remoteDatasource);

  final HostVerificationRemoteDatasource _remoteDatasource;

  @override
  Future<Result<HostVerificationResult>> submit(
    HostVerificationSubmissionDraft draft,
  ) async {
    try {
      final response = await _remoteDatasource.submit(
        HostVerificationSubmissionRequestDto.fromDraft(draft),
      );
      return Ok(response.toEntity());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
