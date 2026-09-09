import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_signup_draft.dart';
import '../../domain/entities/host_signup_result.dart';
import '../../domain/repositories/host_signup_repository.dart';
import '../datasources/host_signup_remote_datasource.dart';
import '../models/host_signup_dto.dart';

class HostSignupRepositoryImpl implements HostSignupRepository {
  const HostSignupRepositoryImpl(this._remoteDatasource);

  final HostSignupRemoteDatasource _remoteDatasource;

  @override
  Future<Result<HostSignupResult>> signup(HostSignupDraft draft) async {
    try {
      final response = await _remoteDatasource.signup(
        HostSignupRequestDto.fromDraft(draft),
      );
      return Ok(response.toEntity());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
