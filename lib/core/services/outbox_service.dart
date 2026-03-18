import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

@singleton
class OutboxService {
  OutboxService({required this.database}) : _uuid = const Uuid();

  final AppDatabase database;
  final Uuid _uuid;

  Future<void> enqueue({
    required String entityName,
    required int recordId,
    required String operation,
    required Map<String, dynamic> payload,
    String? correlationId,
  }) {
    final requestCorrelationId = correlationId ?? _uuid.v4();
    return database.into(database.syncQueue).insert(
          SyncQueueCompanion(
            entityName: Value(entityName),
            recordId: Value(recordId),
            operation: Value(operation),
            payload: Value(jsonEncode(payload)),
            idempotencyKey: Value(_uuid.v4()),
            correlationId: Value(requestCorrelationId),
          ),
        );
  }
}
