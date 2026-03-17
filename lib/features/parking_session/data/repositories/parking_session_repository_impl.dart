import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/parking_session/data/datasources/session_local_datasource.dart';
import 'package:parkflow_manager/features/parking_session/data/datasources/session_remote_datasource.dart';
import 'package:parkflow_manager/features/parking_session/data/models/parking_session_model.dart';
import 'package:parkflow_manager/features/parking_session/data/models/vehicle_model.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';

@Injectable(as: ParkingSessionRepository)
class ParkingSessionRepositoryImpl implements ParkingSessionRepository {

  ParkingSessionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.database,
  });
  final SessionLocalDataSource localDataSource;
  final SessionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AppDatabase database;

  @override
  Future<Either<Failure, List<ParkingSession>>> getActiveSessions(
      String lotId) async {
    try {
      final localSessions = await localDataSource.getActiveSessions(lotId);
      final sessions = await _mapSessionDataToEntities(localSessions);
      return Right(sessions);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Stream<List<ParkingSession>> watchActiveSessions(String lotId) {
    return localDataSource.watchActiveSessions(lotId).asyncMap(
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
    required String vehicleSize,
    required String vehicleColor,
    required int spotId,
    required String lotId,
    required String employeeId,
  }) async {
    try {
      // Insert vehicle locally
      final vehicleData = await localDataSource.insertVehicle(
        VehiclesCompanion(
          licensePlate: Value(licensePlate),
          size: Value(vehicleSize),
          color: Value(vehicleColor),
        ),
      );

      // Insert session locally
      final now = DateTime.now();
      final sessionId = await localDataSource.insertSession(
        ParkingSessionsCompanion(
          vehicleId: Value(vehicleData.id),
          spotId: Value(spotId),
          lotId: Value(lotId),
          entryTime: Value(now),
          status: const Value('active'),
          employeeId: Value(employeeId),
          isSynced: const Value(false),
        ),
      );

      // Queue for sync
      await _queueForSync('sessions', sessionId, 'create', {
        'license_plate': licensePlate,
        'vehicle_size': vehicleSize,
        'vehicle_color': vehicleColor,
        'spot_id': spotId,
        'lot_id': lotId,
        'employee_id': employeeId,
        'entry_time': now.toIso8601String(),
      });

      // Update spot status
      await (database.update(database.parkingSpots)
            ..where((tbl) => tbl.id.equals(spotId)))
          .write(const ParkingSpotsCompanion(status: Value('occupied')));

      final sessionData = await localDataSource.getSessionById(sessionId);
      final session = await _mapSingleSessionData(sessionData);
      return Right(session);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to create session: $e'));
    }
  }

  @override
  Future<Either<Failure, ParkingSession>> flagForCheckout(
      int sessionId) async {
    try {
      await localDataSource.updateSession(
        sessionId,
        const ParkingSessionsCompanion(
          status: Value('flagged_for_checkout'),
        ),
      );
      final sessionData = await localDataSource.getSessionById(sessionId);
      final session = await _mapSingleSessionData(sessionData);
      return Right(session);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to flag session: $e'));
    }
  }

  @override
  Future<Either<Failure, ParkingSession>> completeSession(
    int sessionId, {
    required double totalFee,
  }) async {
    try {
      final now = DateTime.now();
      await localDataSource.updateSession(
        sessionId,
        ParkingSessionsCompanion(
          status: const Value('completed'),
          exitTime: Value(now),
          totalFee: Value(totalFee),
          isSynced: const Value(false),
        ),
      );

      // Free up the parking spot
      final sessionData = await localDataSource.getSessionById(sessionId);
      await (database.update(database.parkingSpots)
            ..where((tbl) => tbl.id.equals(sessionData.spotId)))
          .write(const ParkingSpotsCompanion(status: Value('available')));

      // Queue for sync
      await _queueForSync('sessions', sessionId, 'update', {
        'status': 'completed',
        'exit_time': now.toIso8601String(),
        'total_fee': totalFee,
      });

      final session = await _mapSingleSessionData(sessionData);
      return Right(session);
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
      final sessions =
          await localDataSource.getSessionsByDateRange(start, end);
      final entities = await _mapSessionDataToEntities(sessions);
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get sessions: $e'));
    }
  }

  // ──────────────────── Helpers ────────────────────

  Future<List<ParkingSession>> _mapSessionDataToEntities(
      List<ParkingSessionData> sessions) async {
    final result = <ParkingSession>[];
    for (final session in sessions) {
      result.add(await _mapSingleSessionData(session));
    }
    return result;
  }

  Future<ParkingSession> _mapSingleSessionData(
      ParkingSessionData session) async {
    final vehicleData = await (database.select(database.vehicles)
          ..where((tbl) => tbl.id.equals(session.vehicleId)))
        .getSingle();

    final spotData = await (database.select(database.parkingSpots)
          ..where((tbl) => tbl.id.equals(session.spotId)))
        .getSingle();

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

  Future<void> _queueForSync(
    String entityName,
    int recordId,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    await database.into(database.syncQueue).insert(
          SyncQueueCompanion(
            entityName: Value(entityName),
            recordId: Value(recordId),
            operation: Value(operation),
            payload: Value(jsonEncode(payload)),
          ),
        );
  }
}
