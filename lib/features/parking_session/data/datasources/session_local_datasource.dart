import 'package:drift/drift.dart';
import 'package:parkflow_manager/core/database/app_database.dart';

abstract class SessionLocalDataSource {
  Future<List<ParkingSessionData>> getActiveSessions(String lotId);
  Stream<List<ParkingSessionData>> watchActiveSessions(String lotId);
  Future<ParkingSessionData> getSessionById(int id);
  Future<int> insertSession(ParkingSessionsCompanion session);
  Future<bool> updateSession(int id, ParkingSessionsCompanion session);
  Future<VehicleData> insertVehicle(VehiclesCompanion vehicle);
  Future<List<ParkingSessionData>> searchSessions({
    String? licensePlate,
    String? spotNumber,
  });
  Future<List<ParkingSessionData>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  );
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  final AppDatabase database;

  SessionLocalDataSourceImpl({required this.database});

  @override
  Future<List<ParkingSessionData>> getActiveSessions(String lotId) {
    return (database.select(database.parkingSessions)
          ..where(
            (tbl) =>
                tbl.lotId.equals(lotId) & tbl.status.equals('active'),
          ))
        .get();
  }

  @override
  Stream<List<ParkingSessionData>> watchActiveSessions(String lotId) {
    return (database.select(database.parkingSessions)
          ..where(
            (tbl) =>
                tbl.lotId.equals(lotId) & tbl.status.equals('active'),
          ))
        .watch();
  }

  @override
  Future<ParkingSessionData> getSessionById(int id) {
    return (database.select(database.parkingSessions)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  @override
  Future<int> insertSession(ParkingSessionsCompanion session) {
    return database.into(database.parkingSessions).insert(session);
  }

  @override
  Future<bool> updateSession(int id, ParkingSessionsCompanion session) {
    return (database.update(database.parkingSessions)
          ..where((tbl) => tbl.id.equals(id)))
        .write(session)
        .then((rows) => rows > 0);
  }

  @override
  Future<VehicleData> insertVehicle(VehiclesCompanion vehicle) async {
    final id = await database.into(database.vehicles).insert(vehicle);
    return (database.select(database.vehicles)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  @override
  Future<List<ParkingSessionData>> searchSessions({
    String? licensePlate,
    String? spotNumber,
  }) {
    return (database.select(database.parkingSessions)
          ..where((tbl) {
            Expression<bool> condition = const Constant(true);
            if (spotNumber != null) {
              // Will need a join with ParkingSpots for spotNumber search
            }
            return condition;
          }))
        .get();
  }

  @override
  Future<List<ParkingSessionData>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (database.select(database.parkingSessions)
          ..where(
            (tbl) =>
                tbl.entryTime.isBiggerOrEqualValue(start) &
                tbl.entryTime.isSmallerOrEqualValue(end),
          ))
        .get();
  }
}
