import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
import 'package:parkflow_manager/features/reports/domain/entities/parking_rate_config.dart';

abstract class RateRepository {
  Future<Either<Failure, List<ParkingRateConfig>>> getActiveRates(String lotId);
  Future<Either<Failure, double>> getEffectiveRate(
    String lotId,
    VehicleSize vehicleSize,
    DateTime at,
  );
  Future<Either<Failure, void>> seedDefaultRates(String lotId);
  Future<Either<Failure, ParkingRateConfig>> upsertRate(
    String lotId,
    VehicleSize vehicleSize,
    double ratePerHour,
  );
}
