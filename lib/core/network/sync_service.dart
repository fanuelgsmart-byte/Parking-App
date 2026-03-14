import 'package:logger/logger.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/core/network/network_info.dart';

class SyncService {
  final AppDatabase _database;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;
  final Logger _logger = Logger();

  SyncService({
    required AppDatabase database,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _database = database,
        _apiClient = apiClient,
        _networkInfo = networkInfo;

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
          ..where((tbl) => tbl.isSynced.equals(false)))
        .get();

    for (final item in pendingItems) {
      try {
        await _pushRecord(item);
        await (_database.update(_database.syncQueue)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(const SyncQueueCompanion(isSynced: Value(true)));
      } catch (e) {
        _logger.e('Failed to sync record ${item.id}', error: e);
      }
    }
  }

  Future<void> _pushRecord(SyncQueueData item) async {
    final path = '/${item.tableName}';
    switch (item.operation) {
      case 'create':
        await _apiClient.post(path, data: item.payload);
      case 'update':
        await _apiClient.put('$path/${item.recordId}', data: item.payload);
      case 'delete':
        await _apiClient.delete('$path/${item.recordId}');
    }
  }

  Future<void> _pullRemoteUpdates() async {
    // Pull latest rates, employee data, and lot configuration
    // Implementation will be expanded per feature
  }
}
