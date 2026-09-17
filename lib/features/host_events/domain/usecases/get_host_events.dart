import '../../../../core/error/result.dart';
import '../entities/host_event.dart';
import '../repositories/host_events_repository.dart';

class GetHostEventsUseCase {
  const GetHostEventsUseCase(this._repository);

  final HostEventsRepository _repository;

  Future<Result<List<HostEvent>>> call() => _repository.getEvents();
}
