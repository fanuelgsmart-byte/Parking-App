import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/core/network/network_info.dart';

class SyncService {
  final AppDatabase _database;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;
  final Logger _logger = Logger(
    // Suppress PII in release builds
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  );

  SyncService({
    required AppDatabase database,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _database = database,
        _apiClient = apiClient,
        _networkInfo = networkInfo;

  /// Syncs all pending local changes to the remote API.
  Future<void> syncAll() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      _logger.w('No network connection. Skipping sync.');
      return;
    }

    _logger.i('Starting sync...');

    try {
      await _syncPendingRecords();
      await _pullRemoteUpdates();
      _logger.i('Sync completed successfully.');
    } catch (e) {
      _logger.e('Sync failed', error: e);
    }
  }

  Future<void> _syncPendingRecords() async {
    final pendingItems = await (_database.select(_database.syncQueue)
          ..where((tbl) => tbl.isSynced.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();

    for (final item in pendingItems) {
      try {
        await _pushRecord(item);
        await (_database.update(_database.syncQueue)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(const SyncQueueCompanion(isSynced: Value(true)));
      } catch (e) {
        _logger.e('Failed to sync record ${item.id}', error: e);
        // Continue with next record — don't block the entire queue
      }
    }
  }

  Future<void> _pushRecord(SyncQueueData item) async {
    final path = '/${item.tableName}';

    // Parse the stored JSON payload into a Map for proper serialization
    final dynamic parsedPayload = _safeParsePayload(item.payload);

    switch (item.operation) {
      case 'create':
        await _apiClient.post(path, data: parsedPayload);
      case 'update':
        await _apiClient.put('$path/${item.recordId}', data: parsedPayload);
      case 'delete':
        await _apiClient.delete('$path/${item.recordId}');
      default:
        _logger.w('Unknown sync operation: ${item.operation}');
    }
  }

  /// Safely parses a JSON string payload. Returns the Map on success,
  /// or the raw string if parsing fails (server will reject with 400).
  dynamic _safeParsePayload(String payload) {
    try {
      return jsonDecode(payload);
    } catch (_) {
      _logger.w('Failed to parse sync payload as JSON');
      return payload;
    }
  }

  Future<void> _pullRemoteUpdates() async {
    // Pull latest rates, employee data, and lot configuration
    // Implementation will be expanded per feature
  }
}
