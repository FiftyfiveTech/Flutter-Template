import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_home_summary.dart';
import '../../domain/repositories/host_home_repository.dart';
import '../datasources/host_home_remote_datasource.dart';

class HostHomeRepositoryImpl implements HostHomeRepository {
  const HostHomeRepositoryImpl(this._remoteDatasource);

  final HostHomeRemoteDatasource _remoteDatasource;

  @override
  Future<Result<HostHomeSummary>> getHomeSummary() async {
    try {
      final dto = await _remoteDatasource.getHomeSummary();
      return Ok(dto.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
