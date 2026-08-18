import 'package:drift/drift.dart';

class CounterTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get value => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
