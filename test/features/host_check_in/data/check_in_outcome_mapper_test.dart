import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_check_in/data/models/check_in_outcome_mapper.dart';
import 'package:host_mobile_app/features/host_check_in/domain/entities/check_in_outcome.dart';

void main() {
  test('maps every documented sync outcome', () {
    expect(parseCheckInOutcome('accepted'), CheckInOutcome.accepted);
    expect(parseCheckInOutcome('valid'), CheckInOutcome.accepted);
    expect(
      parseCheckInOutcome('already_checked_in'),
      CheckInOutcome.alreadyCheckedIn,
    );
    expect(
      parseCheckInOutcome('invalid_signature'),
      CheckInOutcome.invalidTicket,
    );
    expect(parseCheckInOutcome('wrong_event'), CheckInOutcome.wrongEvent);
    expect(parseCheckInOutcome('no_booking'), CheckInOutcome.noBooking);
    expect(
      parseCheckInOutcome('booking_not_confirmed'),
      CheckInOutcome.bookingNotConfirmed,
    );
  });

  test('accepts SCREAMING_CASE error codes', () {
    expect(
      parseCheckInOutcome('ALREADY_CHECKED_IN'),
      CheckInOutcome.alreadyCheckedIn,
    );
    expect(parseCheckInOutcome('WRONG_EVENT'), CheckInOutcome.wrongEvent);
  });

  test('unknown values fail closed', () {
    expect(parseCheckInOutcome('something_new'), CheckInOutcome.rejected);
    expect(parseCheckInOutcome(null), CheckInOutcome.rejected);
  });

  test('falls back to the HTTP status for unrecognised codes', () {
    expect(
      checkInOutcomeForError(code: 'CONFLICT', statusCode: 409),
      CheckInOutcome.alreadyCheckedIn,
    );
    expect(
      checkInOutcomeForError(code: 'NOT_FOUND', statusCode: 404),
      CheckInOutcome.noBooking,
    );
    expect(
      checkInOutcomeForError(code: 'X', statusCode: 422),
      CheckInOutcome.rejected,
    );
  });
}
