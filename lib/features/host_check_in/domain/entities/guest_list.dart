import 'check_in_attendee.dart';

class GuestList {
  const GuestList({required this.attendees, required this.isOffline});

  final List<CheckInAttendee> attendees;

  /// Built from the downloaded manifest because the server was unreachable.
  final bool isOffline;
}
