import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';

abstract class PaymentLocalDataSource {
  Future<int> insertPayment(PaymentsCompanion payment);
  Future<bool> updatePayment(int id, PaymentsCompanion payment);
  Future<PaymentData> getPaymentById(int id);
  Future<PaymentData?> getPaymentBySessionId(int sessionId);
  Future<List<PaymentData>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  );
}

@Injectable(as: PaymentLocalDataSource)
class PaymentLocalDataSourceImpl implements PaymentLocalDataSource {

  PaymentLocalDataSourceImpl({required this.database});
  final AppDatabase database;

  @override
  Future<int> insertPayment(PaymentsCompanion payment) {
    return database.into(database.payments).insert(payment);
  }

  @override
  Future<bool> updatePayment(int id, PaymentsCompanion payment) {
    return (database.update(database.payments)
          ..where((tbl) => tbl.id.equals(id)))
        .write(payment)
        .then((rows) => rows > 0);
  }

  @override
  Future<PaymentData> getPaymentById(int id) {
    return (database.select(database.payments)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  @override
  Future<PaymentData?> getPaymentBySessionId(int sessionId) {
    return (database.select(database.payments)
          ..where((tbl) => tbl.sessionId.equals(sessionId)))
        .getSingleOrNull();
  }

  @override
  Future<List<PaymentData>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (database.select(database.payments)
          ..where(
            (tbl) =>
                tbl.createdAt.isBiggerOrEqualValue(start) &
                tbl.createdAt.isSmallerOrEqualValue(end),
          ))
        .get();
  }
}
