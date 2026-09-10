import 'package:drift/drift.dart';

/// Single-row table (`id` always 0) holding where a host is in the
/// H-02..H-05 onboarding wizard, so an app restart resumes on the same
/// step with the same field values instead of restarting the wizard.
///
/// `documentsJson` holds only picked-file metadata and server document
/// ids for slots that finished uploading — never raw file bytes/paths
/// (`docs/features/02-identity-verification.md` §4's "raw ID images are
/// never persisted" applies equally here).
class HostOnboardingProgressTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get step => text()();
  TextColumn get hostType => text().nullable()();
  TextColumn get upiId => text().withDefault(const Constant(''))();
  BoolColumn get servesFood => boolean().withDefault(const Constant(false))();
  BoolColumn get servesAlcohol =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get fssaiValidFrom => dateTime().nullable()();
  DateTimeColumn get fssaiValidTo => dateTime().nullable()();
  DateTimeColumn get exciseValidFrom => dateTime().nullable()();
  DateTimeColumn get exciseValidTo => dateTime().nullable()();
  TextColumn get documentsJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
