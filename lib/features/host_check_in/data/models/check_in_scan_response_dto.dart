import '../../domain/entities/check_in_result.dart';
import 'check_in_outcome_mapper.dart';

/// `POST .../checkin/scan` and `.../checkin/manual` response `data`.
class CheckInScanResponseDto {
  const CheckInScanResponseDto({
    required this.outcome,
    this.firstName,
    this.photoUrl,
    this.scannedAt,
  });

  factory CheckInScanResponseDto.fromJson(Map<String, dynamic> json) {
    final attendee = json['attendee'];
    final scannedAt = json['scannedAt'];
    return CheckInScanResponseDto(
      outcome: json['outcome'] as String? ?? '',
      firstName: attendee is Map ? attendee['firstName'] as String? : null,
      photoUrl: attendee is Map ? attendee['photoUrl'] as String? : null,
      scannedAt: scannedAt is String
          ? DateTime.tryParse(scannedAt)?.toLocal()
          : null,
    );
  }

  final String outcome;
  final String? firstName;
  final String? photoUrl;
  final DateTime? scannedAt;

  CheckInResult toDomain(CheckInMethod method) {
    return CheckInResult(
      outcome: parseCheckInOutcome(outcome),
      method: method,
      attendeeName: firstName,
      photoUrl: photoUrl,
      scannedAt: scannedAt,
    );
  }
}
