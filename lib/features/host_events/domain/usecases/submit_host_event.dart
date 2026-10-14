import '../../../../core/error/result.dart';
import '../entities/host_event.dart';
import '../repositories/host_events_repository.dart';

class SubmitHostEventUseCase {
  const SubmitHostEventUseCase(this._repository);

  final HostEventsRepository _repository;

  Future<Result<HostEvent>> call(String eventId) =>
      _repository.submitEvent(eventId);
}
