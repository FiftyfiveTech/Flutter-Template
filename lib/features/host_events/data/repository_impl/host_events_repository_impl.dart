import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_event.dart';
import '../../domain/entities/host_event_photo.dart';
import '../../domain/repositories/host_events_repository.dart';
import '../datasources/host_events_remote_datasource.dart';
import '../models/host_event_dto.dart';

class HostEventsRepositoryImpl implements HostEventsRepository {
  const HostEventsRepositoryImpl(this._remoteDatasource);

  final HostEventsRemoteDatasource _remoteDatasource;

  @override
  Future<Result<List<HostEvent>>> getEvents() async {
    try {
      final dtos = await _remoteDatasource.getEvents();
      return Ok(dtos.map((dto) => dto.toDomain()).toList());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostEvent>> getEventById(String eventId) async {
    try {
      final dto = await _remoteDatasource.getEventById(eventId);
      return Ok(dto.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostEvent>> saveEvent(HostEvent event) async {
    try {
      final dto = HostEventDto.fromDomain(event);
      final saved = event.id.isEmpty
          ? await _remoteDatasource.createEvent(dto)
          : await _remoteDatasource.updateEvent(event.id, dto);
      return Ok(saved.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostEvent>> submitEvent(String eventId) async {
    try {
      final dto = await _remoteDatasource.submitEvent(eventId);
      return Ok(dto.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostEvent>> cancelEvent(
    String eventId, {
    required String reason,
  }) async {
    try {
      final dto = await _remoteDatasource.cancelEvent(eventId, reason: reason);
      return Ok(dto.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> deleteEvent(String eventId) async {
    try {
      await _remoteDatasource.deleteEvent(eventId);
      return const Ok(null);
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostEventPhoto>> uploadEventPhoto({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final dto = await _remoteDatasource.uploadEventPhoto(
        filePath: filePath,
        fileName: fileName,
      );
      return Ok(dto.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
