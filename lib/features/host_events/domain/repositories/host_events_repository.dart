import '../../../../core/error/result.dart';
import '../entities/host_event.dart';
import '../entities/host_event_photo.dart';

abstract class HostEventsRepository {
  Future<Result<List<HostEvent>>> getEvents();

  Future<Result<HostEvent>> getEventById(String eventId);

  /// Creates when `event.id` is empty, otherwise updates (`PATCH`) the
  /// existing event — mirrors `HostVenuesRepository.saveVenue`.
  Future<Result<HostEvent>> saveEvent(HostEvent event);

  Future<Result<HostEventPhoto>> uploadEventPhoto({
    required String filePath,
    required String fileName,
  });
}
