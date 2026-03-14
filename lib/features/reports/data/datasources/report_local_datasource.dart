import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';

abstract class ReportLocalDataSource {
  Future<List<ParkingSessionData>> getCompletedSessionsByDateRange(
    String lotId,
    DateTime start,
    DateTime end,
  );

  Future<List<PaymentData>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  );

  Future<Map<String, int>> getSessionCountByEmployee(
    String lotId,
    DateTime start,
    DateTime end,
  );
}

@Injectable(as: ReportLocalDataSource)
class ReportLocalDataSourceImpl implements ReportLocalDataSource {
  final AppDatabase database;

  ReportLocalDataSourceImpl({required this.database});

  @override
  Future<List<ParkingSessionData>> getCompletedSessionsByDateRange(
    String lotId,
    DateTime start,
    DateTime end,
  ) {
    return (database.select(database.parkingSessions)
          ..where(
            (tbl) =>
                tbl.lotId.equals(lotId) &
                tbl.status.equals('completed') &
                tbl.entryTime.isBiggerOrEqualValue(start) &
                tbl.entryTime.isSmallerOrEqualValue(end),
          ))
        .get();
  }

  @override
  Future<List<PaymentData>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (database.select(database.payments)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.createdAt.isBiggerOrEqualValue(start) &
                tbl.createdAt.isSmallerOrEqualValue(end),
          ))
        .get();
  }

  @override
  Future<Map<String, int>> getSessionCountByEmployee(
    String lotId,
    DateTime start,
    DateTime end,
  ) async {
    final sessions = await (database.select(database.parkingSessions)
          ..where(
            (tbl) =>
                tbl.lotId.equals(lotId) &
                tbl.status.equals('completed') &
                tbl.entryTime.isBiggerOrEqualValue(start) &
                tbl.entryTime.isSmallerOrEqualValue(end),
          ))
        .get();

    final counts = <String, int>{};
    for (final session in sessions) {
      counts[session.employeeId] =
          (counts[session.employeeId] ?? 0) + 1;
    }
    return counts;
  }
}
