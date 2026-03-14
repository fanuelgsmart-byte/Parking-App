import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/core/utils/usecase.dart';
import 'package:parkflow_manager/features/lot_map/domain/entities/parking_spot.dart';
import 'package:parkflow_manager/features/lot_map/domain/repositories/lot_repository.dart';

@injectable
class GetLotSpots extends UseCase<List<ParkingSpot>, String> {
  final LotRepository repository;

  GetLotSpots({required this.repository});

  @override
  Future<Either<Failure, List<ParkingSpot>>> call(String lotId) {
    return repository.getSpots(lotId);
  }
}
