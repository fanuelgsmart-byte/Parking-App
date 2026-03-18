import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/services/outbox_service.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/parking_session/data/datasources/session_local_datasource.dart';
import 'package:parkflow_manager/features/parking_session/data/datasources/session_remote_datasource.dart';
import 'package:parkflow_manager/features/parking_session/data/models/parking_session_model.dart';
import 'package:parkflow_manager/features/parking_session/data/models/vehicle_model.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';

@Injectable(as: ParkingSessionRepository)
class ParkingSessionRepositoryImpl implements ParkingSessionRepository {
  ParkingSessionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.database,
    required this.outboxService,
  });

  final SessionLocalDataSource localDataSource;
  final SessionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AppDatabase database;
  final OutboxService outboxService;

  @override
  Future<Either<Failure, List<ParkingSession>>> getOpenSessions(
    String lotId,
  ) async {
    try {
      final localSessions = await localDataSource.getOpenSessions(lotId);
      final sessions = await _mapSessionDataToEntities(localSessions);
      return Right(sessions);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Stream<List<ParkingSession>> watchOpenSessions(String lotId) {
    return localDataSource.watchOpenSessions(lotId).asyncMap(
          _mapSessionDataToEntities,
        );
  }

  @override
  Future<Either<Failure, ParkingSession>> getSessionById(int id) async {
    try {
      final sessionData = await localDataSource.getSessionById(id);
      final session = await _mapSingleSessionData(sessionData);
      return Right(session);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParkingSession>> createSession({
    required String licensePlate,
    required VehicleSize vehicleSize,
    required String vehicleColor,
    required String lotId,
    required String employeeId,
  }) async {
    try {
      final sessionData = await database.transaction<ParkingSessionData>(() async {
        final spot = await localDataSource.getAvailableSpot(lotId, vehicleSize);
        if (spot == null) {
          throw const CacheException(
            message: 'No available parking spot matches this vehicle.',
          );
        }

        final vehicleData = await localDataSource.insertVehicle(
          VehiclesCompanion(
            licensePlate: Value(licensePlate),
            size: Value(vehicleSize.name),
            color: Value(vehicleColor),
          ),
        );

        final now = DateTime.now();
        final sessionId = await localDataSource.insertSession(
          ParkingSessionsCompanion(
            vehicleId: Value(vehicleData.id),
            spotId: Value(spot.id),
            lotId: Value(lotId),
            entryTime: Value(now),
            status: Value(ParkingSessionModel.statusToString(SessionStatus.active)),
            employeeId: Value(employeeId),
            isSynced: const Value(false),
          ),
        );

        await (database.update(database.parkingSpots)
              ..where((tbl) => tbl.id.equals(spot.id)))
            .write(const ParkingSpotsCompanion(status: Value('occupied')));

        await outboxService.enqueue(
          entityName: 'sessions',
          recordId: sessionId,
          operation: 'create',
          payload: {
            'license_plate': licensePlate,
            'vehicle_size': vehicleSize.name,
            'vehicle_color': vehicleColor,
            'spot_id': spot.id,
            'lot_id': lotId,
            'employee_id': employeeId,
            'entry_time': now.toIso8601String(),
          },
        );

        return localDataSource.getSessionById(sessionId);
      });

      final session = await _mapSingleSessionData(sessionData);
      return Right(session);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to create session: $e'));
    }
  }

  @override
  Future<Either<Failure, ParkingSession>> flagForCheckout(int sessionId) {
    return _transitionSession(
      sessionId,
      SessionStatus.flaggedForCheckout,
      allowedFrom: const [SessionStatus.active],
    );
  }

  @override
  Future<Either<Failure, ParkingSession>> markPaymentPending(int sessionId) {
    return _transitionSession(
      sessionId,
      SessionStatus.paymentPending,
      allowedFrom: const [SessionStatus.flaggedForCheckout],
    );
  }

  @override
  Future<Either<Failure, ParkingSession>> completeSession(
    int sessionId, {
    required double totalFee,
  }) async {
    try {
      final updatedSession = await database.transaction<ParkingSessionData>(
        () async {
          final current = await localDataSource.getSessionById(sessionId);
          final currentStatus = ParkingSessionModel.parseStatus(current.status);
          if (!const [
            SessionStatus.flaggedForCheckout,
            SessionStatus.paymentPending,
          ].contains(currentStatus)) {
            throw const CacheException(
              message: 'Only checkout-ready sessions can be completed.',
            );
          }

          final now = DateTime.now();
          await localDataSource.updateSession(
            sessionId,
            ParkingSessionsCompanion(
              status: Value(
                ParkingSessionModel.statusToString(SessionStatus.completed),
              ),
              exitTime: Value(now),
              totalFee: Value(totalFee),
              isSynced: const Value(false),
            ),
          );

          await (database.update(database.parkingSpots)
                ..where((tbl) => tbl.id.equals(current.spotId)))
              .write(const ParkingSpotsCompanion(status: Value('available')));

          await outboxService.enqueue(
            entityName: 'sessions',
            recordId: sessionId,
            operation: 'update',
            payload: {
              'status': 'completed',
              'exit_time': now.toIso8601String(),
              'total_fee': totalFee,
            },
          );

          return localDataSource.getSessionById(sessionId);
        },
      );

      final session = await _mapSingleSessionData(updatedSession);
      return Right(session);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to complete session: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ParkingSession>>> searchSessions({
    String? licensePlate,
    String? vehicleColor,
    String? spotNumber,
  }) async {
    try {
      final sessions = await localDataSource.searchSessions(
        licensePlate: licensePlate,
        spotNumber: spotNumber,
      );
      final entities = await _mapSessionDataToEntities(sessions);
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure(message: 'Search failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ParkingSession>>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final sessions = await localDataSource.getSessionsByDateRange(start, end);
      final entities = await _mapSessionDataToEntities(sessions);
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get sessions: $e'));
    }
  }

  Future<Either<Failure, ParkingSession>> _transitionSession(
    int sessionId,
    SessionStatus nextStatus, {
    required List<SessionStatus> allowedFrom,
  }) async {
    try {
      final current = await localDataSource.getSessionById(sessionId);
      final currentStatus = ParkingSessionModel.parseStatus(current.status);
      if (!allowedFrom.contains(currentStatus) ||
          !currentStatus.canTransitionTo(nextStatus)) {
        return Left(
          ValidationFailure(
            message:
                'Cannot move session from ${currentStatus.name} to ${nextStatus.name}.',
          ),
        );
      }

      await localDataSource.updateSession(
        sessionId,
        ParkingSessionsCompanion(
          status: Value(ParkingSessionModel.statusToString(nextStatus)),
        ),
      );
      final updated = await localDataSource.getSessionById(sessionId);
      final session = await _mapSingleSessionData(updated);
      return Right(session);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update session: $e'));
    }
  }

  Future<List<ParkingSession>> _mapSessionDataToEntities(
    List<ParkingSessionData> sessions,
  ) async {
    final result = <ParkingSession>[];
    for (final session in sessions) {
      result.add(await _mapSingleSessionData(session));
    }
    return result;
  }

  Future<ParkingSession> _mapSingleSessionData(ParkingSessionData session) async {
    final vehicleData = await (database.select(database.vehicles)
          ..where((tbl) => tbl.id.equals(session.vehicleId)))
        .getSingle();

    final spotData = await localDataSource.getSpotById(session.spotId);

    final vehicleModel = VehicleModel(
      id: vehicleData.id,
      licensePlate: vehicleData.licensePlate,
      size: vehicleData.size,
      color: vehicleData.color,
      createdAt: vehicleData.createdAt,
    );

    return ParkingSessionModel(
      id: session.id,
      vehicle: vehicleModel,
      spotId: session.spotId,
      spotNumber: spotData.spotNumber,
      lotId: session.lotId,
      entryTime: session.entryTime,
      exitTime: session.exitTime,
      totalFee: session.totalFee,
      status: session.status,
      employeeId: session.employeeId,
      isSynced: session.isSynced,
    ).toEntity();
  }
}
