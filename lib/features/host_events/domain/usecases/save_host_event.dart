import '../../../../core/error/result.dart';
import '../entities/host_event.dart';
import '../repositories/host_events_repository.dart';

class SaveHostEventUseCase {
  const SaveHostEventUseCase(this._repository);

  final HostEventsRepository _repository;

  Future<Result<HostEvent>> call(HostEvent event) =>
      _repository.saveEvent(event);
}
