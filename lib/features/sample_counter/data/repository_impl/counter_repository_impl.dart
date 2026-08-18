// ignore: unused_import
import 'dart:convert';
// ignore: unused_import
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/counter_record.dart';
import '../../domain/repositories/counter_repository.dart';
import '../datasources/counter_local_datasource.dart';
import '../datasources/counter_remote_datasource.dart';
import '../models/counter_dto.dart';

class CounterRepositoryImpl implements CounterRepository {
  const CounterRepositoryImpl(
    this._localDatasource,
    this._remoteDatasource,
    this._database, // required if using outbox sync strategy
  );

  final CounterLocalDatasource _localDatasource;
  final CounterRemoteDatasource _remoteDatasource;
  // ignore: unused_field
  final AppDatabase _database;

  @override
  Future<Result<CounterRecord>> getCounter() async {
    try {
      // Try local cache first
      final cached = await _localDatasource.getLocalCount();
      if (cached != null) {
        return Ok(cached.toEntity());
      }
      
      // Fallback to remote if cache is empty
      final remoteDto = await _remoteDatasource.fetchRemoteCount();
      await _localDatasource.saveLocalCount(remoteDto);
      return Ok(remoteDto.toEntity());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<CounterRecord>> updateCounter(int value) async {
    final dto = CounterDto(
      id: 1, // Single global counter instance
      value: value,
      updatedAt: DateTime.now(),
    );

    /* =========================================================================
       STRATEGY A (Default): Direct writes to remote, then cache on success.
       ========================================================================= */
    try {
      // 1. Write directly to remote
      await _remoteDatasource.updateRemoteCount(dto);
      
      // 2. Cache locally on successful remote write
      await _localDatasource.saveLocalCount(dto);
      
      return Ok(dto.toEntity());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }

    /* =========================================================================
       STRATEGY C (Optional Opt-In): Local-first write + outbox sync queuing.
       To enable offline outbox syncing, uncomment this block and comment out 
       Strategy A above.
       =========================================================================
    try {
      // 1. Write to Drift database locally immediately
      await _localDatasource.saveLocalCount(dto);

      // 2. Enqueue the sync task in our outbox table
      await _database.into(_database.syncQueueEntries).insert(
        SyncQueueEntriesCompanion(
          entityType: const Value('counter'),
          entityKey: const Value('global_counter'),
          payload: Value(jsonEncode(dto.toJson())),
        ),
      );

      return Ok(dto.toEntity());
    } catch (_) {
      return const Err(CacheFailure());
    }
    ========================================================================= */
  }
}
