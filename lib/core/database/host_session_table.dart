import 'package:drift/drift.dart';

/// Single-row table (`id` always 0) holding the signed-in host's session,
/// so an app restart doesn't require signing in again mid-onboarding.
class HostSessionTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get accessToken => text()();
  TextColumn get userId => text()();
  TextColumn get accountStatus => text()();

  /// The business/organiser name entered at H-01 signup — the backend has
  /// no session/profile field for this yet, so it's persisted locally to
  /// show on Home ("hi, $businessName") without a network round trip.
  /// Empty for hosts who signed in via OTP login rather than signup on
  /// this device.
  TextColumn get businessName => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
