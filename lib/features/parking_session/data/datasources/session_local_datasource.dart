import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
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

@Injectable(as: SessionLocalDataSource)
class SessionLocalDataSourceImpl implements SessionLocalDataSource {

  SessionLocalDataSourceImpl({required this.database});
  final AppDatabase database;

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
  }) async {
    // Build a custom select with joins for cross-table filtering
    final query = database.select(database.parkingSessions).join([
      innerJoin(
        database.vehicles,
        database.vehicles.id
            .equalsExp(database.parkingSessions.vehicleId),
      ),
      innerJoin(
        database.parkingSpots,
        database.parkingSpots.id
            .equalsExp(database.parkingSessions.spotId),
      ),
    ]);

    if (licensePlate != null && licensePlate.isNotEmpty) {
      query.where(database.vehicles.licensePlate.like('%$licensePlate%'));
    }

    if (spotNumber != null && spotNumber.isNotEmpty) {
      query.where(database.parkingSpots.spotNumber.like('%$spotNumber%'));
    }

    final rows = await query.get();
    return rows
        .map((row) => row.readTable(database.parkingSessions))
        .toList();
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
