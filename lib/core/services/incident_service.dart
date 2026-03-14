import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:parkflow_manager/core/database/app_database.dart';

enum IncidentType { violation, unauthorized, dispute, other }

extension IncidentTypeExtension on IncidentType {
  String get value {
    switch (this) {
      case IncidentType.violation:
        return 'violation';
      case IncidentType.unauthorized:
        return 'unauthorized';
      case IncidentType.dispute:
        return 'dispute';
      case IncidentType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case IncidentType.violation:
        return 'Parking Violation';
      case IncidentType.unauthorized:
        return 'Unauthorized Vehicle';
      case IncidentType.dispute:
        return 'Customer Dispute';
      case IncidentType.other:
        return 'Other Incident';
    }
  }
}

class IncidentRecord {
  final int id;
  final String lotId;
  final String employeeId;
  final IncidentType type;
  final String description;
  final String? licensePlate;
  final DateTime occurredAt;
  final bool isSynced;

  const IncidentRecord({
    required this.id,
    required this.lotId,
    required this.employeeId,
    required this.type,
    required this.description,
    this.licensePlate,
    required this.occurredAt,
    required this.isSynced,
  });
}

/// Service for logging and retrieving parking incidents.
class IncidentService {
  final AppDatabase database;

  IncidentService({required this.database});

  /// Log a new incident. Returns the created [IncidentRecord].
  Future<IncidentRecord> logIncident({
    required String lotId,
    required String employeeId,
    required IncidentType type,
    required String description,
    String? licensePlate,
  }) async {
    final now = DateTime.now();
    final id = await database.into(database.incidents).insert(
          IncidentsCompanion(
            lotId: Value(lotId),
            employeeId: Value(employeeId),
            type: Value(type.value),
            description: Value(description),
            licensePlate: Value(licensePlate),
            occurredAt: Value(now),
            isSynced: const Value(false),
          ),
        );

    // Queue sync
    await database.into(database.syncQueue).insert(
          SyncQueueCompanion(
            tableName: const Value('incidents'),
            recordId: Value(id),
            operation: const Value('create'),
            payload: Value(jsonEncode({
              'lot_id': lotId,
              'employee_id': employeeId,
              'type': type.value,
              'description': description,
              'license_plate': licensePlate,
              'occurred_at': now.toIso8601String(),
            })),
          ),
        );

    return IncidentRecord(
      id: id,
      lotId: lotId,
      employeeId: employeeId,
      type: type,
      description: description,
      licensePlate: licensePlate,
      occurredAt: now,
      isSynced: false,
    );
  }

  /// Retrieve incidents for a lot, ordered by most recent first.
  Future<List<IncidentRecord>> getIncidents(
    String lotId, {
    int limit = 50,
  }) async {
    final rows = await (database.select(database.incidents)
          ..where((tbl) => tbl.lotId.equals(lotId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.occurredAt)])
          ..limit(limit))
        .get();

    return rows
        .map(
          (r) => IncidentRecord(
            id: r.id,
            lotId: r.lotId,
            employeeId: r.employeeId,
            type: _parseType(r.type),
            description: r.description,
            licensePlate: r.licensePlate,
            occurredAt: r.occurredAt,
            isSynced: r.isSynced,
          ),
        )
        .toList();
  }

  static IncidentType _parseType(String type) {
    switch (type) {
      case 'violation':
        return IncidentType.violation;
      case 'unauthorized':
        return IncidentType.unauthorized;
      case 'dispute':
        return IncidentType.dispute;
      default:
        return IncidentType.other;
    }
  }
}
