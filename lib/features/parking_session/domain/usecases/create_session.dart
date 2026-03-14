import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/core/utils/usecase.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';

class CreateSession extends UseCase<ParkingSession, CreateSessionParams> {
  final ParkingSessionRepository repository;

  CreateSession({required this.repository});

  @override
  Future<Either<Failure, ParkingSession>> call(CreateSessionParams params) {
    return repository.createSession(
      licensePlate: params.licensePlate,
      vehicleSize: params.vehicleSize,
      vehicleColor: params.vehicleColor,
      spotId: params.spotId,
      lotId: params.lotId,
      employeeId: params.employeeId,
    );
  }
}

class CreateSessionParams {
  final String licensePlate;
  final String vehicleSize;
  final String vehicleColor;
  final int spotId;
  final String lotId;
  final String employeeId;

  const CreateSessionParams({
    required this.licensePlate,
    required this.vehicleSize,
    required this.vehicleColor,
    required this.spotId,
    required this.lotId,
    required this.employeeId,
  });
}
