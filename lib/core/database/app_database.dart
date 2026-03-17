import 'package:drift/drift.dart';

part 'app_database.g.dart';

// ──────────────────────────── Tables ────────────────────────────

@DataClassName('VehicleData')
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get licensePlate => text().withLength(min: 1, max: 20)();
  TextColumn get size => text()(); // small, medium, large
  TextColumn get color => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ParkingSpotData')
class ParkingSpots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get spotNumber => text().withLength(min: 1, max: 10)();
  TextColumn get lotId => text()();
  TextColumn get status => text().withDefault(const Constant('available'))();
  TextColumn get size => text()(); // small, medium, large
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
  TextColumn get method => text()(); // cash, digital
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
  TextColumn get vehicleSize => text()(); // small, medium, large
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
  TextColumn get role => text()(); // employee, manager
  TextColumn get assignedLotId => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('IncidentData')
class Incidents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lotId => text()();
  TextColumn get employeeId => text()();
  TextColumn get type => text()(); // violation, unauthorized, dispute
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
  TextColumn get operation => text()(); // create, update, delete
  TextColumn get payload => text()(); // JSON serialized data
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ──────────────────────────── Database ────────────────────────────

@DriftDatabase(tables: [
  Vehicles,
  ParkingSpots,
  ParkingSessions,
  Payments,
  ParkingRates,
  Employees,
  Incidents,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
    );
  }
}
