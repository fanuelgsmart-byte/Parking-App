import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/payment/data/datasources/payment_local_datasource.dart';
import 'package:parkflow_manager/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:parkflow_manager/features/payment/data/models/payment_model.dart';
import 'package:parkflow_manager/features/payment/domain/entities/payment.dart';
import 'package:parkflow_manager/features/payment/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentLocalDataSource localDataSource;
  final PaymentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AppDatabase database;

  PaymentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.database,
  });

  @override
  Future<Either<Failure, Payment>> processPayment({
    required int sessionId,
    required double amount,
    required PaymentMethod method,
  }) async {
    if (method == PaymentMethod.cash) {
      return recordCashPayment(sessionId: sessionId, amount: amount);
    } else {
      return _processDigitalPayment(sessionId: sessionId, amount: amount);
    }
  }

  @override
  Future<Either<Failure, Payment>> recordCashPayment({
    required int sessionId,
    required double amount,
  }) async {
    try {
      final now = DateTime.now();
      final paymentId = await localDataSource.insertPayment(
        PaymentsCompanion(
          sessionId: Value(sessionId),
          amount: Value(amount),
          method: const Value('cash'),
          status: const Value('completed'),
          paidAt: Value(now),
          isSynced: const Value(false),
        ),
      );

      // Queue for sync
      await database.into(database.syncQueue).insert(
            SyncQueueCompanion(
              tableName: const Value('payments'),
              recordId: Value(paymentId),
              operation: const Value('create'),
              payload: Value(jsonEncode({
                'session_id': sessionId,
                'amount': amount,
                'method': 'cash',
                'paid_at': now.toIso8601String(),
              })),
            ),
          );

      final paymentData = await localDataSource.getPaymentById(paymentId);
      return Right(_mapPaymentDataToEntity(paymentData));
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to record cash payment: $e'),
      );
    }
  }

  Future<Either<Failure, Payment>> _processDigitalPayment({
    required int sessionId,
    required double amount,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(
          message:
              'Digital payment requires an internet connection. Please use cash payment.',
        ),
      );
    }

    try {
      // Create pending payment locally
      final paymentId = await localDataSource.insertPayment(
        PaymentsCompanion(
          sessionId: Value(sessionId),
          amount: Value(amount),
          method: const Value('digital'),
          status: const Value('pending'),
          isSynced: const Value(false),
        ),
      );

      final paymentData = await localDataSource.getPaymentById(paymentId);
      return Right(_mapPaymentDataToEntity(paymentData));
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to initiate digital payment: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> fetchQrCode(
      int sessionId, double amount) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(
          message: 'Internet connection required for QR code payment.',
        ),
      );
    }

    try {
      final qrUrl = await remoteDataSource.fetchQrCode(sessionId, amount);
      return Right(qrUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Payment>> confirmDigitalPayment(
      String transactionRef) async {
    try {
      final remotePayment =
          await remoteDataSource.confirmDigitalPayment(transactionRef);

      // Update local record
      final localPayment =
          await localDataSource.getPaymentBySessionId(remotePayment.sessionId);
      if (localPayment != null) {
        await localDataSource.updatePayment(
          localPayment.id,
          PaymentsCompanion(
            status: const Value('completed'),
            transactionRef: Value(transactionRef),
            paidAt: Value(DateTime.now()),
            isSynced: const Value(true),
          ),
        );
      }

      return Right(remotePayment.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final payments =
          await localDataSource.getPaymentsByDateRange(start, end);
      return Right(
        payments.map((p) => _mapPaymentDataToEntity(p)).toList(),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get payments: $e'));
    }
  }

  Payment _mapPaymentDataToEntity(PaymentData data) {
    return PaymentModel(
      id: data.id,
      sessionId: data.sessionId,
      amount: data.amount,
      method: data.method,
      status: data.status,
      transactionRef: data.transactionRef,
      paidAt: data.paidAt,
      isSynced: data.isSynced,
    ).toEntity();
  }
}
