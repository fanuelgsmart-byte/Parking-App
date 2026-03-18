import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/session/app_session_context.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/core/utils/usecase.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';

@injectable
class CreateSession extends UseCase<ParkingSession, CreateSessionParams> {
  CreateSession({required this.repository});

  final ParkingSessionRepository repository;

  @override
  Future<Either<Failure, ParkingSession>> call(CreateSessionParams params) {
    return repository.createSession(
      licensePlate: params.licensePlate,
      vehicleSize: params.vehicleSize,
      vehicleColor: params.vehicleColor,
      lotId: params.lotId,
      employeeId: params.employeeId,
    );
  }
}

class CreateSessionParams extends Equatable {
  const CreateSessionParams({
    required this.licensePlate,
    required this.vehicleSize,
    required this.vehicleColor,
    required this.lotId,
    required this.employeeId,
  });

  final String licensePlate;
  final VehicleSize vehicleSize;
  final String vehicleColor;
  final LotId lotId;
  final EmployeeId employeeId;

  @override
  List<Object?> get props => [
        licensePlate,
        vehicleSize,
        vehicleColor,
        lotId,
        employeeId,
      ];
}
