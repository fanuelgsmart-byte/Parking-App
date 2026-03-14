import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';

abstract class ParkingSessionRepository {
  Future<Either<Failure, List<ParkingSession>>> getActiveSessions(
      String lotId);

  Stream<List<ParkingSession>> watchActiveSessions(String lotId);

  Future<Either<Failure, ParkingSession>> getSessionById(int id);

  Future<Either<Failure, ParkingSession>> createSession({
    required String licensePlate,
    required String vehicleSize,
    required String vehicleColor,
    required int spotId,
    required String lotId,
    required String employeeId,
  });

  Future<Either<Failure, ParkingSession>> flagForCheckout(int sessionId);

  Future<Either<Failure, ParkingSession>> completeSession(
    int sessionId, {
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
