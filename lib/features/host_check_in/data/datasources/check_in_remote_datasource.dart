import '../../../../core/network/base_api_client.dart';
import '../models/check_in_attendee_dto.dart';
import '../models/check_in_manifest_dto.dart';
import '../models/check_in_scan_response_dto.dart';
import '../models/check_in_sync_dto.dart';

abstract class CheckInRemoteDatasource {
  Future<CheckInScanResponseDto> scan({
    required String eventId,
    required String qrCode,
    required String scannerDeviceId,
  });

  Future<CheckInScanResponseDto> manualCheckIn({
    required String eventId,
    required String bookingId,
    required String scannerDeviceId,
  });

  Future<List<CheckInAttendeeDto>> getAttendees(String eventId);

  Future<CheckInManifestDto> getManifest(String eventId);

  Future<List<CheckInSyncResultDto>> sync({
    required String eventId,
    required String scannerDeviceId,
    required List<CheckInSyncScanDto> scans,
  });
}

class CheckInRestDatasource implements CheckInRemoteDatasource {
  CheckInRestDatasource(this._client);

  final BaseApiClient _client;

  String _base(String eventId) => '/api/v1/host/events/$eventId';

  @override
  Future<CheckInScanResponseDto> scan({
    required String eventId,
    required String qrCode,
    required String scannerDeviceId,
  }) async {
    final response = await _client.post(
      '${_base(eventId)}/checkin/scan',
      data: {'qrCode': qrCode, 'scannerDeviceId': scannerDeviceId},
    );
    final body = response.data as Map<String, dynamic>;
    return CheckInScanResponseDto.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<CheckInScanResponseDto> manualCheckIn({
    required String eventId,
    required String bookingId,
    required String scannerDeviceId,
  }) async {
    final response = await _client.post(
      '${_base(eventId)}/checkin/manual',
      data: {'bookingId': bookingId, 'scannerDeviceId': scannerDeviceId},
    );
    final body = response.data as Map<String, dynamic>;
    return CheckInScanResponseDto.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<CheckInAttendeeDto>> getAttendees(String eventId) async {
    final response = await _client.get('${_base(eventId)}/attendees');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => CheckInAttendeeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CheckInManifestDto> getManifest(String eventId) async {
    final response = await _client.get('${_base(eventId)}/checkin/manifest');
    final body = response.data as Map<String, dynamic>;
    return CheckInManifestDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<CheckInSyncResultDto>> sync({
    required String eventId,
    required String scannerDeviceId,
    required List<CheckInSyncScanDto> scans,
  }) async {
    final response = await _client.post(
      '${_base(eventId)}/checkin/sync',
      data: {
        'scannerDeviceId': scannerDeviceId,
        'scans': scans.map((s) => s.toJson()).toList(),
      },
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return (data['results'] as List<dynamic>)
        .map((e) => CheckInSyncResultDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
