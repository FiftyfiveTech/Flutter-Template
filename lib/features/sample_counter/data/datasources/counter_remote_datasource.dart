import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/network/base_api_client.dart';
import '../models/counter_dto.dart';

abstract interface class CounterRemoteDatasource {
  Future<CounterDto> fetchRemoteCount();
  Future<void> updateRemoteCount(CounterDto count);
}

/// 1. REST API implementation (using generic BaseApiClient and Dio)
class CounterRestDatasource implements CounterRemoteDatasource {
  CounterRestDatasource(this._client);
  final BaseApiClient _client;

  @override
  Future<CounterDto> fetchRemoteCount() async {
    final response = await _client.get('/counter');
    return CounterDto.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateRemoteCount(CounterDto count) async {
    await _client.post('/counter', data: count.toJson());
  }
}

/// 2. Firebase / Cloud Firestore implementation
class CounterFirebaseDatasource implements CounterRemoteDatasource {
  CounterFirebaseDatasource(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Future<CounterDto> fetchRemoteCount() async {
    final snapshot = await _firestore.collection('counters').doc('global').get();
    final data = snapshot.data();
    if (data == null) {
      return CounterDto(id: 1, value: 0, updatedAt: DateTime.now());
    }
    return CounterDto.fromJson(data);
  }

  @override
  Future<void> updateRemoteCount(CounterDto count) async {
    await _firestore
        .collection('counters')
        .doc('global')
        .set(count.toJson(), SetOptions(merge: true));
  }
}
