import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/services/outbox_service.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
import 'package:parkflow_manager/features/reports/data/datasources/rate_local_datasource.dart';
import 'package:parkflow_manager/features/reports/domain/entities/parking_rate_config.dart';
import 'package:parkflow_manager/features/reports/domain/repositories/rate_repository.dart';

@Injectable(as: RateRepository)
class RateRepositoryImpl implements RateRepository {
  RateRepositoryImpl({
    required this.localDataSource,
    required this.outboxService,
  });

  final RateLocalDataSource localDataSource;
  final OutboxService outboxService;

  @override
  Future<Either<Failure, List<ParkingRateConfig>>> getActiveRates(
    String lotId,
  ) async {
    try {
      final rates = await localDataSource.getActiveRates(lotId);
      return Right(rates.map(_mapRate).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load rates: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getEffectiveRate(
    String lotId,
    VehicleSize vehicleSize,
    DateTime at,
  ) async {
    try {
      final rate = await localDataSource.getEffectiveRate(lotId, vehicleSize, at);
      if (rate == null) {
        return const Left(
          ValidationFailure(message: 'No active rate exists for this vehicle size.'),
        );
      }
      return Right(rate.ratePerHour);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to resolve rate: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> seedDefaultRates(String lotId) async {
    try {
      await localDataSource.seedDefaultRates(lotId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to seed rates: $e'));
    }
  }

  @override
  Future<Either<Failure, ParkingRateConfig>> upsertRate(
    String lotId,
    VehicleSize vehicleSize,
    double ratePerHour,
  ) async {
    try {
      final rate = await localDataSource.upsertRate(lotId, vehicleSize, ratePerHour);
      await outboxService.enqueue(
        entityName: 'rates',
        recordId: rate.id,
        operation: 'create',
        payload: {
          'lot_id': lotId,
          'vehicle_size': vehicleSize.name,
          'rate_per_hour': ratePerHour,
          'effective_from': rate.effectiveFrom.toIso8601String(),
        },
      );
      return Right(_mapRate(rate));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update rate: $e'));
    }
  }

  ParkingRateConfig _mapRate(dynamic data) {
    return ParkingRateConfig(
      id: data.id as int,
      lotId: data.lotId as String,
      vehicleSize: VehicleSize.values.firstWhere(
        (size) => size.name == (data.vehicleSize as String),
        orElse: () => VehicleSize.medium,
      ),
      ratePerHour: data.ratePerHour as double,
      effectiveFrom: data.effectiveFrom as DateTime,
      effectiveTo: data.effectiveTo as DateTime?,
      isActive: data.isActive as bool,
    );
  }
}
