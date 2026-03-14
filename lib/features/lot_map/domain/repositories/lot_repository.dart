import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/lot_map/domain/entities/parking_lot.dart';
import 'package:parkflow_manager/features/lot_map/domain/entities/parking_spot.dart';

abstract class LotRepository {
  Future<Either<Failure, List<ParkingLot>>> getLots();
  Future<Either<Failure, ParkingLot>> getLotById(String lotId);
  Future<Either<Failure, List<ParkingSpot>>> getSpots(String lotId);
  Stream<List<ParkingSpot>> watchSpots(String lotId);
  Future<Either<Failure, ParkingSpot>> updateSpotStatus(
    int spotId,
    SpotStatus status,
  );
}
