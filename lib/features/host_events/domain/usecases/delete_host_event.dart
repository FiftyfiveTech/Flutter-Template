import '../../../../core/error/result.dart';
import '../repositories/host_events_repository.dart';

class DeleteHostEventUseCase {
  const DeleteHostEventUseCase(this._repository);

  final HostEventsRepository _repository;

  Future<Result<void>> call(String eventId) => _repository.deleteEvent(eventId);
}
