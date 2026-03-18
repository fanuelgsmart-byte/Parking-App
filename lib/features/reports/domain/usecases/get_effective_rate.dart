import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/core/utils/usecase.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
import 'package:parkflow_manager/features/reports/domain/repositories/rate_repository.dart';

@injectable
class GetEffectiveRateUseCase extends UseCase<double, GetEffectiveRateParams> {
  GetEffectiveRateUseCase({required this.repository});

  final RateRepository repository;

  @override
  Future<Either<Failure, double>> call(GetEffectiveRateParams params) {
    return repository.getEffectiveRate(
      params.lotId,
      params.vehicleSize,
      params.at,
    );
  }
}

class GetEffectiveRateParams {
  const GetEffectiveRateParams({
    required this.lotId,
    required this.vehicleSize,
    required this.at,
  });

  final String lotId;
  final VehicleSize vehicleSize;
  final DateTime at;
}
