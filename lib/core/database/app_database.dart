import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DataClassName('VehicleData')
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get licensePlate => text().withLength(min: 1, max: 20)();
  TextColumn get size => text()();
  TextColumn get color => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ParkingSpotData')
class ParkingSpots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get spotNumber => text().withLength(min: 1, max: 10)();
  TextColumn get lotId => text()();
  TextColumn get status => text().withDefault(const Constant('available'))();
  TextColumn get size => text()();
  IntColumn get row => integer().nullable()();
  IntColumn get col => integer().nullable()();
}

@DataClassName('ParkingSessionData')
class ParkingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id)();
  IntColumn get spotId => integer().references(ParkingSpots, #id)();
  TextColumn get lotId => text()();
  DateTimeColumn get entryTime => dateTime()();
  DateTimeColumn get exitTime => dateTime().nullable()();
  RealColumn get totalFee => real().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get employeeId => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PaymentData')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(ParkingSessions, #id)();
  RealColumn get amount => real()();
  TextColumn get method => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get transactionRef => text().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ParkingRateData')
class ParkingRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lotId => text()();
  TextColumn get vehicleSize => text()();
  RealColumn get ratePerHour => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get effectiveFrom => dateTime()();
  DateTimeColumn get effectiveTo => dateTime().nullable()();
}

@DataClassName('EmployeeData')
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get role => text()();
  TextColumn get assignedLotId => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {remoteId},
      ];
}

@DataClassName('IncidentData')
class Incidents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lotId => text()();
  TextColumn get employeeId => text()();
  TextColumn get type => text()();
  TextColumn get description => text()();
  TextColumn get licensePlate => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityName => text()();
  IntColumn get recordId => integer()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  TextColumn get idempotencyKey => text().unique()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get correlationId => text()();
  TextColumn get remoteVersion => text().nullable()();
  BoolColumn get deadLettered => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ReportCacheData')
class ReportCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cacheKey => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {cacheKey},
      ];
}

@DriftDatabase(tables: [
  Vehicles,
  ParkingSpots,
  ParkingSessions,
  Payments,
  ParkingRates,
  Employees,
  Incidents,
  SyncQueue,
  ReportCaches,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createEnterpriseIndexes();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(syncQueue, syncQueue.idempotencyKey);
          await m.addColumn(syncQueue, syncQueue.attemptCount);
          await m.addColumn(syncQueue, syncQueue.lastError);
          await m.addColumn(syncQueue, syncQueue.nextAttemptAt);
          await m.addColumn(syncQueue, syncQueue.correlationId);
          await m.addColumn(syncQueue, syncQueue.remoteVersion);
          await m.addColumn(syncQueue, syncQueue.deadLettered);
          await m.createTable(reportCaches);
        }
        await _createEnterpriseIndexes();
      },
    );
  }

  Future<void> _createEnterpriseIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_lot_status ON parking_sessions (lot_id, status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_entry_time ON parking_sessions (entry_time)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_employee_id ON parking_sessions (employee_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_retry ON sync_queue (is_synced, dead_lettered, next_attempt_at, created_at)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_rate_per_size ON parking_rates (lot_id, vehicle_size) WHERE is_active = 1',
    );
    await customStatement(
      "CREATE UNIQUE INDEX IF NOT EXISTS uniq_open_session_per_spot ON parking_sessions (spot_id) WHERE status IN ('active', 'flagged_for_checkout', 'payment_pending')",
    );
  }
}


