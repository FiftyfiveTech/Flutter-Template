import '../../domain/entities/check_in_outcome.dart';

/// Maps a backend outcome string (`valid`, `accepted`,
/// `already_checked_in`, `invalid_signature`, ...) or error envelope
/// `code` (e.g. `ALREADY_CHECKED_IN`) to a [CheckInOutcome]. Case- and
/// separator-insensitive, since online error codes are SCREAMING_CASE and
/// sync outcomes are snake_case. Unknown values become
/// [CheckInOutcome.rejected] (never "accepted"), so a new server code can
/// only ever fail closed.
CheckInOutcome parseCheckInOutcome(String? raw) {
  final value = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
  if (value == 'valid' || value == 'accepted' || value == 'checked_in') {
    return CheckInOutcome.accepted;
  }
  if (value.contains('already')) return CheckInOutcome.alreadyCheckedIn;
  if (value.contains('wrong_event') || value.contains('event_mismatch')) {
    return CheckInOutcome.wrongEvent;
  }
  if (value.contains('not_confirmed')) {
    return CheckInOutcome.bookingNotConfirmed;
  }
  if (value.contains('no_booking') || value.contains('booking_not_found')) {
    return CheckInOutcome.noBooking;
  }
  if (value.contains('signature') ||
      value.contains('invalid') ||
      value.contains('qr')) {
    return CheckInOutcome.invalidTicket;
  }
  return CheckInOutcome.rejected;
}

/// For an error response whose `code` didn't map to a known outcome, the
/// HTTP status still says something useful about the ticket.
CheckInOutcome checkInOutcomeForError({String? code, int? statusCode}) {
  final fromCode = parseCheckInOutcome(code);
  if (fromCode != CheckInOutcome.rejected) return fromCode;
  return switch (statusCode) {
    409 => CheckInOutcome.alreadyCheckedIn,
    404 => CheckInOutcome.noBooking,
    400 => CheckInOutcome.invalidTicket,
    _ => CheckInOutcome.rejected,
  };
}
