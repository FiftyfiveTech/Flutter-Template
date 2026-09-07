import 'package:drift/drift.dart';

class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // e.g. 'counter'
  TextColumn get entityKey => text()(); // e.g. 'userId|countId'
  TextColumn get payload => text()(); // JSON payload
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
