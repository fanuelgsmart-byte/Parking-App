import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';

abstract class RateLocalDataSource {
  Future<List<ParkingRateData>> getActiveRates(String lotId);
  Future<ParkingRateData?> getEffectiveRate(
    String lotId,
    VehicleSize vehicleSize,
    DateTime at,
  );
  Future<void> seedDefaultRates(String lotId);
  Future<ParkingRateData> upsertRate(
    String lotId,
    VehicleSize vehicleSize,
    double ratePerHour,
  );
}

@Injectable(as: RateLocalDataSource)
class RateLocalDataSourceImpl implements RateLocalDataSource {
  RateLocalDataSourceImpl({required this.database});

  final AppDatabase database;

  @override
  Future<List<ParkingRateData>> getActiveRates(String lotId) {
    return (database.select(database.parkingRates)
          ..where(
            (tbl) => tbl.lotId.equals(lotId) & tbl.isActive.equals(true),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.vehicleSize)]))
        .get();
  }

  @override
  Future<ParkingRateData?> getEffectiveRate(
    String lotId,
    VehicleSize vehicleSize,
    DateTime at,
  ) {
    return (database.select(database.parkingRates)
          ..where(
            (tbl) =>
                tbl.lotId.equals(lotId) &
                tbl.vehicleSize.equals(vehicleSize.name) &
                tbl.effectiveFrom.isSmallerOrEqualValue(at) &
                (tbl.effectiveTo.isNull() |
                    tbl.effectiveTo.isBiggerThanValue(at)),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.effectiveFrom)]))
        .getSingleOrNull();
  }

  @override
  Future<void> seedDefaultRates(String lotId) async {
    for (final (size, rate) in [
      (VehicleSize.small, 3.0),
      (VehicleSize.medium, 5.0),
      (VehicleSize.large, 8.0),
    ]) {
      await upsertRate(lotId, size, rate);
    }
  }

  @override
  Future<ParkingRateData> upsertRate(
    String lotId,
    VehicleSize vehicleSize,
    double ratePerHour,
  ) async {
    final now = DateTime.now();
    await (database.update(database.parkingRates)
          ..where(
            (tbl) =>
                tbl.lotId.equals(lotId) &
                tbl.vehicleSize.equals(vehicleSize.name) &
                tbl.isActive.equals(true),
          ))
        .write(
      ParkingRatesCompanion(
        isActive: const Value(false),
        effectiveTo: Value(now),
      ),
    );

    final id = await database.into(database.parkingRates).insert(
          ParkingRatesCompanion(
            lotId: Value(lotId),
            vehicleSize: Value(vehicleSize.name),
            ratePerHour: Value(ratePerHour),
            effectiveFrom: Value(now),
            isActive: const Value(true),
          ),
        );

    return (database.select(database.parkingRates)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }
}
