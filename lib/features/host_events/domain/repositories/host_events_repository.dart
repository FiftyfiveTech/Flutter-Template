import '../../../../core/error/result.dart';
import '../entities/host_event.dart';
import '../entities/host_event_photo.dart';

abstract class HostEventsRepository {
  Future<Result<List<HostEvent>>> getEvents();

  Future<Result<HostEvent>> getEventById(String eventId);

  /// Creates when `event.id` is empty, otherwise updates (`PATCH`) the
  /// existing event — mirrors `HostVenuesRepository.saveVenue`.
  Future<Result<HostEvent>> saveEvent(HostEvent event);

  /// Moves a draft to `submitted` for review/publishing.
  Future<Result<HostEvent>> submitEvent(String eventId);

  /// Cancels the event and initiates attendee refunds on the backend.
  Future<Result<HostEvent>> cancelEvent(
    String eventId, {
    required String reason,
  });

  /// Soft-deletes a draft event (the backend only allows drafts).
  Future<Result<void>> deleteEvent(String eventId);

  Future<Result<HostEventPhoto>> uploadEventPhoto({
    required String filePath,
    required String fileName,
  });
}
