import 'package:host_mobile_app/core/network/base_api_client.dart';
import 'package:host_mobile_app/features/host_check_in/data/datasources/check_in_remote_datasource.dart';
import 'package:host_mobile_app/features/host_check_in/data/models/check_in_attendee_dto.dart';
import 'package:host_mobile_app/features/host_check_in/data/models/check_in_manifest_dto.dart';
import 'package:host_mobile_app/features/host_check_in/data/models/check_in_scan_response_dto.dart';
import 'package:host_mobile_app/features/host_check_in/data/models/check_in_sync_dto.dart';

NetworkException offline() => NetworkException('Failed to connect to host');

class FakeCheckInRemote implements CheckInRemoteDatasource {
  Object? scanError;
  CheckInScanResponseDto scanResponse = const CheckInScanResponseDto(
    outcome: 'valid',
    firstName: 'Asha',
  );
  Object? manualError;
  CheckInScanResponseDto manualResponse = const CheckInScanResponseDto(
    outcome: 'valid',
  );
  Object? attendeesError;
  List<CheckInAttendeeDto> attendees = const [];
  Object? manifestError;
  CheckInManifestDto? manifest;
  Object? syncError;
  List<CheckInSyncResultDto> Function(List<CheckInSyncScanDto> scans)? onSync;

  final syncCalls = <List<CheckInSyncScanDto>>[];
  final manualCalls = <String>[];
  final deviceIds = <String>{};

  @override
  Future<CheckInScanResponseDto> scan({
    required String eventId,
    required String qrCode,
    required String scannerDeviceId,
  }) async {
    deviceIds.add(scannerDeviceId);
    if (scanError != null) throw scanError!;
    return scanResponse;
  }

  @override
  Future<CheckInScanResponseDto> manualCheckIn({
    required String eventId,
    required String bookingId,
    required String scannerDeviceId,
  }) async {
    deviceIds.add(scannerDeviceId);
    manualCalls.add(bookingId);
    if (manualError != null) throw manualError!;
    return manualResponse;
  }

  @override
  Future<List<CheckInAttendeeDto>> getAttendees(String eventId) async {
    if (attendeesError != null) throw attendeesError!;
    return attendees;
  }

  @override
  Future<CheckInManifestDto> getManifest(String eventId) async {
    if (manifestError != null) throw manifestError!;
    return manifest!;
  }

  @override
  Future<List<CheckInSyncResultDto>> sync({
    required String eventId,
    required String scannerDeviceId,
    required List<CheckInSyncScanDto> scans,
  }) async {
    deviceIds.add(scannerDeviceId);
    syncCalls.add(scans);
    if (syncError != null) throw syncError!;
    return onSync!(scans);
  }
}
