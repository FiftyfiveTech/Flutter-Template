import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:after_hours/core/database/app_database.dart';
import 'package:after_hours/features/sample_counter/data/datasources/counter_local_datasource.dart';
import 'package:after_hours/features/sample_counter/data/models/counter_dto.dart';

void main() {
  late AppDatabase database;
  late DriftCounterLocalDatasource localDatasource;

  setUp(() {
    // Open in-memory connection for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    localDatasource = DriftCounterLocalDatasource(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Local Counter Datasource Tests', () {
    test('should save and retrieve counter DTO from Drift', () async {
      final dto = CounterDto(id: 1, value: 42, updatedAt: DateTime.now());
      
      await localDatasource.saveLocalCount(dto);
      final retrieved = await localDatasource.getLocalCount();

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 1);
      expect(retrieved.value, 42);
    });

    test('should return null when no counter has been saved', () async {
      final retrieved = await localDatasource.getLocalCount();
      expect(retrieved, isNull);
    });
  });
}
