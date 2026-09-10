import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_login_result.dart';
import '../../domain/repositories/host_login_repository.dart';
import '../datasources/host_login_remote_datasource.dart';
import '../models/host_login_dto.dart';

class HostLoginRepositoryImpl implements HostLoginRepository {
  const HostLoginRepositoryImpl(this._remoteDatasource);

  final HostLoginRemoteDatasource _remoteDatasource;

  @override
  Future<Result<void>> requestOtp(String phoneNumber) async {
    try {
      await _remoteDatasource.requestOtp(
        OtpRequestDto.fromPhoneNumber(phoneNumber),
      );
      return const Ok(null);
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostLoginResult>> verifyOtp(
    String phoneNumber,
    String code,
  ) async {
    try {
      final response = await _remoteDatasource.verifyOtp(
        OtpVerifyRequestDto.from(phoneNumber, code),
      );
      return Ok(response.toEntity());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
