import 'package:drift/drift.dart';
import 'package:parkflow_manager/core/database/app_database.dart';

abstract class LotLocalDataSource {
  Future<List<ParkingSpotData>> getSpots(String lotId);
  Stream<List<ParkingSpotData>> watchSpots(String lotId);
  Future<bool> updateSpotStatus(int spotId, String status);
}

class LotLocalDataSourceImpl implements LotLocalDataSource {
  final AppDatabase database;

  LotLocalDataSourceImpl({required this.database});

  @override
  Future<List<ParkingSpotData>> getSpots(String lotId) {
    return (database.select(database.parkingSpots)
          ..where((tbl) => tbl.lotId.equals(lotId)))
        .get();
  }

  @override
  Stream<List<ParkingSpotData>> watchSpots(String lotId) {
    return (database.select(database.parkingSpots)
          ..where((tbl) => tbl.lotId.equals(lotId)))
        .watch();
  }

  @override
  Future<bool> updateSpotStatus(int spotId, String status) {
    return (database.update(database.parkingSpots)
          ..where((tbl) => tbl.id.equals(spotId)))
        .write(ParkingSpotsCompanion(status: Value(status)))
        .then((rows) => rows > 0);
  }
}
