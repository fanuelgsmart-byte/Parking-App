import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';

abstract class SessionLocalDataSource {
  Future<List<ParkingSessionData>> getOpenSessions(String lotId);
  Stream<List<ParkingSessionData>> watchOpenSessions(String lotId);
  Future<ParkingSessionData> getSessionById(int id);
  Future<int> insertSession(ParkingSessionsCompanion session);
  Future<bool> updateSession(int id, ParkingSessionsCompanion session);
  Future<VehicleData> insertVehicle(VehiclesCompanion vehicle);
  Future<ParkingSpotData?> getAvailableSpot(String lotId, VehicleSize vehicleSize);
  Future<ParkingSpotData> getSpotById(int id);
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
  Future<List<ParkingSessionData>> getOpenSessions(String lotId) {
    return (database.select(database.parkingSessions)
          ..where(
            (tbl) => tbl.lotId.equals(lotId) &
                tbl.status.isIn(const [
                  'active',
                  'flagged_for_checkout',
                  'payment_pending',
                ]),
          ))
        .get();
  }

  @override
  Stream<List<ParkingSessionData>> watchOpenSessions(String lotId) {
    return (database.select(database.parkingSessions)
          ..where(
            (tbl) => tbl.lotId.equals(lotId) &
                tbl.status.isIn(const [
                  'active',
                  'flagged_for_checkout',
                  'payment_pending',
                ]),
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
    return (database.select(database.vehicles)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  @override
  Future<ParkingSpotData?> getAvailableSpot(
    String lotId,
    VehicleSize vehicleSize,
  ) async {
    final exactMatch = await (database.select(database.parkingSpots)
          ..where(
            (tbl) =>
                tbl.lotId.equals(lotId) &
                tbl.status.equals('available') &
                tbl.size.equals(vehicleSize.name),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.spotNumber)]))
        .getSingleOrNull();
    if (exactMatch != null) {
      return exactMatch;
    }

    return (database.select(database.parkingSpots)
          ..where(
            (tbl) =>
                tbl.lotId.equals(lotId) & tbl.status.equals('available'),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.spotNumber)]))
        .getSingleOrNull();
  }

  @override
  Future<ParkingSpotData> getSpotById(int id) {
    return (database.select(database.parkingSpots)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  @override
  Future<List<ParkingSessionData>> searchSessions({
    String? licensePlate,
    String? spotNumber,
  }) async {
    final query = database.select(database.parkingSessions).join([
      innerJoin(
        database.vehicles,
        database.vehicles.id.equalsExp(database.parkingSessions.vehicleId),
      ),
      innerJoin(
        database.parkingSpots,
        database.parkingSpots.id.equalsExp(database.parkingSessions.spotId),
      ),
    ]);

    if (licensePlate != null && licensePlate.isNotEmpty) {
      query.where(database.vehicles.licensePlate.like('%$licensePlate%'));
    }

    if (spotNumber != null && spotNumber.isNotEmpty) {
      query.where(database.parkingSpots.spotNumber.like('%$spotNumber%'));
    }

    final rows = await query.get();
    return rows.map((row) => row.readTable(database.parkingSessions)).toList();
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
