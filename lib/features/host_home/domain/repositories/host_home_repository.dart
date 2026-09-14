import '../../../../core/error/result.dart';
import '../entities/host_home_summary.dart';

abstract class HostHomeRepository {
  Future<Result<HostHomeSummary>> getHomeSummary();
}
