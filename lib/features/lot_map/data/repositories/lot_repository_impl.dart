import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/lot_map/data/datasources/lot_local_datasource.dart';
import 'package:parkflow_manager/features/lot_map/data/datasources/lot_remote_datasource.dart';
import 'package:parkflow_manager/features/lot_map/data/models/parking_spot_model.dart';
import 'package:parkflow_manager/features/lot_map/domain/entities/parking_lot.dart';
import 'package:parkflow_manager/features/lot_map/domain/entities/parking_spot.dart';
import 'package:parkflow_manager/features/lot_map/domain/repositories/lot_repository.dart';

class LotRepositoryImpl implements LotRepository {
  final LotLocalDataSource localDataSource;
  final LotRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LotRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ParkingLot>>> getLots() async {
    try {
      if (await networkInfo.isConnected) {
        final remoteLots = await remoteDataSource.getLots();
        return Right(remoteLots.map((m) => m.toEntity()).toList());
      }
      return const Left(
        NetworkFailure(message: 'Cannot fetch lots while offline.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, ParkingLot>> getLotById(String lotId) async {
    try {
      final remoteLot = await remoteDataSource.getLotById(lotId);
      return Right(remoteLot.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<ParkingSpot>>> getSpots(String lotId) async {
    try {
      final localSpots = await localDataSource.getSpots(lotId);
      return Right(
        localSpots.map((s) => _mapSpotDataToEntity(s)).toList(),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get spots: $e'));
    }
  }

  @override
  Stream<List<ParkingSpot>> watchSpots(String lotId) {
    return localDataSource.watchSpots(lotId).map(
          (spots) => spots.map((s) => _mapSpotDataToEntity(s)).toList(),
        );
  }

  @override
  Future<Either<Failure, ParkingSpot>> updateSpotStatus(
    int spotId,
    SpotStatus status,
  ) async {
    try {
      final statusStr = status.name;
      await localDataSource.updateSpotStatus(spotId, statusStr);
      final spots = await localDataSource.getSpots('');
      final spot = spots.firstWhere((s) => s.id == spotId);
      return Right(_mapSpotDataToEntity(spot));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update spot: $e'));
    }
  }

  ParkingSpot _mapSpotDataToEntity(ParkingSpotData data) {
    return ParkingSpotModel(
      id: data.id,
      spotNumber: data.spotNumber,
      lotId: data.lotId,
      status: data.status,
      size: data.size,
      row: data.row,
      col: data.col,
    ).toEntity();
  }
}
