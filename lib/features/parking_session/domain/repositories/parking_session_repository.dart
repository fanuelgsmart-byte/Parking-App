import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/session/app_session_context.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';

abstract class ParkingSessionRepository {
  Future<Either<Failure, List<ParkingSession>>> getOpenSessions(LotId lotId);

  Stream<List<ParkingSession>> watchOpenSessions(LotId lotId);

  Future<Either<Failure, ParkingSession>> getSessionById(SessionId id);

  Future<Either<Failure, ParkingSession>> createSession({
    required String licensePlate,
    required VehicleSize vehicleSize,
    required String vehicleColor,
    required LotId lotId,
    required EmployeeId employeeId,
  });

  Future<Either<Failure, ParkingSession>> flagForCheckout(SessionId sessionId);

  Future<Either<Failure, ParkingSession>> markPaymentPending(
    SessionId sessionId,
  );

  Future<Either<Failure, ParkingSession>> completeSession(
    SessionId sessionId, {
    required double totalFee,
  });

  Future<Either<Failure, List<ParkingSession>>> searchSessions({
    String? licensePlate,
    String? vehicleColor,
    String? spotNumber,
  });

  Future<Either<Failure, List<ParkingSession>>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  );
}
