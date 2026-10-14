import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/host_event.dart';
import '../repositories/host_events_repository.dart';

/// Max length of a cancellation reason, per the API's `CancelEventDto`.
const kMaxCancelReasonLength = 500;

class CancelHostEventUseCase {
  const CancelHostEventUseCase(this._repository);

  final HostEventsRepository _repository;

  Future<Result<HostEvent>> call(String eventId, {required String reason}) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Err(ValidationFailure(message: 'Add a reason for cancelling.')),
      );
    }
    if (trimmed.length > kMaxCancelReasonLength) {
      return Future.value(
        const Err(
          ValidationFailure(
            message:
                'Reason must be $kMaxCancelReasonLength characters or fewer.',
          ),
        ),
      );
    }
    return _repository.cancelEvent(eventId, reason: trimmed);
  }
}
