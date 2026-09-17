import '../../../../core/error/result.dart';
import '../entities/host_event.dart';
import '../repositories/host_events_repository.dart';

class GetHostEventByIdUseCase {
  const GetHostEventByIdUseCase(this._repository);

  final HostEventsRepository _repository;

  Future<Result<HostEvent>> call(String eventId) =>
      _repository.getEventById(eventId);
}
