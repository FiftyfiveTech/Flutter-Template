import '../../../../core/error/result.dart';
import '../entities/host_event.dart';
import '../entities/host_event_photo.dart';

abstract class HostEventsRepository {
  Future<Result<HostEvent>> saveEvent(HostEvent event);

  Future<Result<HostEventPhoto>> uploadEventPhoto({
    required String filePath,
    required String fileName,
  });
}
