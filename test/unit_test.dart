import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app_template/core/error/failures.dart';
import 'package:flutter_app_template/core/error/result.dart';
import 'package:flutter_app_template/features/sample_counter/domain/entities/counter_record.dart';
import 'package:flutter_app_template/features/sample_counter/domain/repositories/counter_repository.dart';
import 'package:flutter_app_template/features/sample_counter/domain/usecases/increment_counter.dart';
import 'package:flutter_app_template/features/sample_counter/data/models/counter_dto.dart';

class MockCounterRepository implements CounterRepository {
  int? lastUpdatedValue;

  @override
  Future<Result<CounterRecord>> getCounter() async {
    return Ok(CounterRecord(id: 1, value: 0, updatedAt: DateTime.now()));
  }

  @override
  Future<Result<CounterRecord>> updateCounter(int value) async {
    lastUpdatedValue = value;
    return Ok(CounterRecord(id: 1, value: value, updatedAt: DateTime.now()));
  }
}

void main() {
  group('IncrementCounter Usecase Tests', () {
    late MockCounterRepository mockRepository;
    late IncrementCounter incrementCounter;

    setUp(() {
      mockRepository = MockCounterRepository();
      incrementCounter = IncrementCounter(mockRepository);
    });

    test('should increment counter successfully when under 100', () async {
      final result = await incrementCounter(10);

      expect(result, isA<Ok<CounterRecord>>());
      result.when(
        ok: (record) {
          expect(record.value, 11);
          expect(mockRepository.lastUpdatedValue, 11);
        },
        err: (_) => fail('Expected Ok, got Err'),
      );
    });

    test('should fail with ValidationFailure when counter is 100 or more', () async {
      final result = await incrementCounter(100);

      expect(result, isA<Err<CounterRecord>>());
      result.when(
        ok: (_) => fail('Expected Err, got Ok'),
        err: (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Counter cannot exceed 100.');
        },
      );
    });
  });

  group('CounterDto Mapping Tests', () {
    test('should map DTO to Entity correctly', () {
      final date = DateTime.now();
      final dto = CounterDto(id: 1, value: 5, updatedAt: date);
      final entity = dto.toEntity();

      expect(entity.id, 1);
      expect(entity.value, 5);
      expect(entity.updatedAt, date);
    });

    test('should map Entity to DTO correctly', () {
      final date = DateTime.now();
      final entity = CounterRecord(id: 1, value: 8, updatedAt: date);
      final dto = CounterDto.fromEntity(entity);

      expect(dto.id, 1);
      expect(dto.value, 8);
      expect(dto.updatedAt, date);
    });
  });
}
