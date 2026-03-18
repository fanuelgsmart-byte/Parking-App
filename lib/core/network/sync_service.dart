import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/core/network/network_info.dart';

class SyncService {
  SyncService({
    required AppDatabase database,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _database = database,
        _apiClient = apiClient,
        _networkInfo = networkInfo;

  final AppDatabase _database;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;
  final Logger _logger = Logger(
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  );

  Future<void>? _inFlightSync;
  static const _maxAttempts = 5;

  Future<void> syncAll() {
    final running = _inFlightSync;
    if (running != null) {
      return running;
    }

    final completer = Completer<void>();
    _inFlightSync = completer.future;

    () async {
      try {
        final isConnected = await _networkInfo.isConnected;
        if (!isConnected) {
          _logger.w('No network connection. Skipping sync.');
          return;
        }

        await _syncPendingRecords();
        await _pullRemoteUpdates();
        _logger.i('Sync completed successfully.');
      } catch (e, stackTrace) {
        _logger.e('Sync failed', error: e, stackTrace: stackTrace);
      } finally {
        _inFlightSync = null;
        completer.complete();
      }
    }();

    return completer.future;
  }

  Future<int> deadLetterCount() async {
    final result = await (_database.selectOnly(_database.syncQueue)
          ..addColumns([_database.syncQueue.id.count()])
          ..where(_database.syncQueue.deadLettered.equals(true)))
        .getSingle();
    return result.read(_database.syncQueue.id.count()) ?? 0;
  }

  Future<List<SyncQueueData>> getDeadLetters({int limit = 50}) {
    return (_database.select(_database.syncQueue)
          ..where((tbl) => tbl.deadLettered.equals(true))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> _syncPendingRecords() async {
    final now = DateTime.now();
    final pendingItems = await (_database.select(_database.syncQueue)
          ..where(
            (tbl) =>
                tbl.isSynced.equals(false) &
                tbl.deadLettered.equals(false) &
                (tbl.nextAttemptAt.isNull() |
                    tbl.nextAttemptAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();

    for (final item in pendingItems) {
      try {
        final response = await _pushRecord(item);
        await (_database.update(_database.syncQueue)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(
          SyncQueueCompanion(
            isSynced: const Value(true),
            lastError: const Value(null),
            remoteVersion: Value(
              response.headers.value('x-resource-version') ??
                  response.headers.value('etag'),
            ),
          ),
        );
      } catch (e) {
        await _markRetry(item, e.toString());
      }
    }
  }

  Future<Response<dynamic>> _pushRecord(SyncQueueData item) async {
    final path = '/${item.entityName}';
    final parsedPayload = _safeParsePayload(item.payload);
    final headers = {
      'X-Idempotency-Key': item.idempotencyKey,
      'X-Correlation-Id': item.correlationId,
    };

    switch (item.operation) {
      case 'create':
        return _apiClient.post(path, data: parsedPayload, headers: headers);
      case 'update':
        return _apiClient.put(
          '$path/${item.recordId}',
          data: parsedPayload,
          headers: headers,
        );
      case 'delete':
        return _apiClient.delete('$path/${item.recordId}', headers: headers);
      default:
        throw StateError('Unknown sync operation: ${item.operation}');
    }
  }

  dynamic _safeParsePayload(String payload) {
    try {
      return jsonDecode(payload);
    } catch (_) {
      return payload;
    }
  }

  Future<void> _markRetry(SyncQueueData item, String error) async {
    final attemptCount = item.attemptCount + 1;
    final deadLettered = attemptCount >= _maxAttempts;
    final backoffSeconds = min(pow(2, attemptCount).toInt(), 300);

    await (_database.update(_database.syncQueue)
          ..where((tbl) => tbl.id.equals(item.id)))
        .write(
      SyncQueueCompanion(
        attemptCount: Value(attemptCount),
        lastError: Value(error),
        nextAttemptAt: Value(
          deadLettered
              ? DateTime.now()
              : DateTime.now().add(Duration(seconds: backoffSeconds)),
        ),
        deadLettered: Value(deadLettered),
      ),
    );
  }

  Future<void> _pullRemoteUpdates() async {
    final lotIds = await _knownLotIds();
    for (final lotId in lotIds) {
      await _syncEmployees(lotId);
      await _syncRates(lotId);
    }
  }

  Future<Set<String>> _knownLotIds() async {
    final lotIds = <String>{};
    final spots = await _database.select(_database.parkingSpots).get();
    final rates = await _database.select(_database.parkingRates).get();
    final employees = await _database.select(_database.employees).get();

    for (final spot in spots) {
      lotIds.add(spot.lotId);
    }
    for (final rate in rates) {
      lotIds.add(rate.lotId);
    }
    for (final employee in employees) {
      if (employee.assignedLotId != null && employee.assignedLotId!.isNotEmpty) {
        lotIds.add(employee.assignedLotId!);
      }
    }
    return lotIds;
  }

  Future<void> _syncEmployees(String lotId) async {
    final response = await _apiClient.get(
      ApiConstants.employees,
      queryParameters: {'lot_id': lotId},
    );
    final employees = (response.data['employees'] as List?) ?? const [];
    for (final raw in employees) {
      final employee = raw as Map<String, dynamic>;
      final remoteId = employee['id'] as String;
      final existing = await (_database.select(_database.employees)
            ..where((tbl) => tbl.remoteId.equals(remoteId)))
          .getSingleOrNull();
      final companion = EmployeesCompanion(
        remoteId: Value(remoteId),
        name: Value(employee['name'] as String),
        email: Value(employee['email'] as String),
        role: Value(employee['role'] as String),
        assignedLotId: Value(employee['assigned_lot_id'] as String?),
        isActive: Value(employee['is_active'] as bool? ?? true),
      );
      if (existing == null) {
        await _database.into(_database.employees).insert(companion);
      } else {
        await (_database.update(_database.employees)
              ..where((tbl) => tbl.remoteId.equals(remoteId)))
            .write(companion);
      }
    }
  }

  Future<void> _syncRates(String lotId) async {
    final response = await _apiClient.get(
      ApiConstants.rates,
      queryParameters: {'lot_id': lotId},
    );
    final rates = (response.data['rates'] as List?) ?? const [];
    for (final raw in rates) {
      final rate = raw as Map<String, dynamic>;
      final size = rate['vehicle_size'] as String;
      final value = (rate['rate_per_hour'] as num).toDouble();
      final effectiveFrom = rate['effective_from'] != null
          ? DateTime.parse(rate['effective_from'] as String)
          : DateTime.now();
      await (_database.update(_database.parkingRates)
            ..where(
              (tbl) =>
                  tbl.lotId.equals(lotId) &
                  tbl.vehicleSize.equals(size) &
                  tbl.isActive.equals(true),
            ))
          .write(
        ParkingRatesCompanion(
          isActive: const Value(false),
          effectiveTo: Value(DateTime.now()),
        ),
      );
      await _database.into(_database.parkingRates).insert(
            ParkingRatesCompanion(
              lotId: Value(lotId),
              vehicleSize: Value(size),
              ratePerHour: Value(value),
              effectiveFrom: Value(effectiveFrom),
              isActive: const Value(true),
            ),
          );
    }
  }
}
