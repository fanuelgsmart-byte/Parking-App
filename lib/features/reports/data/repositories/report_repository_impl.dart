import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/reports/data/datasources/report_local_datasource.dart';
import 'package:parkflow_manager/features/reports/domain/entities/occupancy_report.dart';
import 'package:parkflow_manager/features/reports/domain/entities/revenue_report.dart';
import 'package:parkflow_manager/features/reports/domain/repositories/report_repository.dart';

@Injectable(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {

  ReportRepositoryImpl({
    required this.localDataSource,
    required this.database,
  });
  final ReportLocalDataSource localDataSource;
  final AppDatabase database;

  @override
  Future<Either<Failure, RevenueReport>> getRevenueReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final sessions = await localDataSource.getCompletedSessionsByDateRange(
        lotId,
        startDate,
        endDate,
      );

      final payments =
          await localDataSource.getPaymentsByDateRange(startDate, endDate);

      double totalRevenue = 0;
      double cashRevenue = 0;
      double digitalRevenue = 0;
      final dailyMap = <String, _DailyAccum>{};
      final sizeRevenue = <String, double>{};

      for (final payment in payments) {
        totalRevenue += payment.amount;
        if (payment.method == 'cash') {
          cashRevenue += payment.amount;
        } else {
          digitalRevenue += payment.amount;
        }

        final dateKey = payment.createdAt.toIso8601String().substring(0, 10);
        dailyMap.putIfAbsent(
          dateKey,
          () => _DailyAccum(date: DateTime.parse(dateKey)),
        );
        dailyMap[dateKey]!.revenue += payment.amount;
        dailyMap[dateKey]!.count++;
      }

      // Group by vehicle size
      for (final session in sessions) {
        final vehicle = await (database.select(database.vehicles)
              ..where((tbl) => tbl.id.equals(session.vehicleId)))
            .getSingleOrNull();
        if (vehicle != null && session.totalFee != null) {
          sizeRevenue[vehicle.size] =
              (sizeRevenue[vehicle.size] ?? 0) + session.totalFee!;
        }
      }

      final report = RevenueReport(
        startDate: startDate,
        endDate: endDate,
        totalRevenue: totalRevenue,
        cashRevenue: cashRevenue,
        digitalRevenue: digitalRevenue,
        totalSessions: sessions.length,
        dailyBreakdown: dailyMap.values
            .map((d) => DailyRevenue(
                  date: d.date,
                  revenue: d.revenue,
                  sessionCount: d.count,
                ))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)),
        revenueByVehicleSize: sizeRevenue,
      );

      return Right(report);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to generate revenue report: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, OccupancyReport>> getOccupancyReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final sessions = await localDataSource.getCompletedSessionsByDateRange(
        lotId,
        startDate,
        endDate,
      );

      // Calculate hourly distribution
      final hourCounts = List.filled(24, 0);
      var totalDuration = Duration.zero;

      for (final session in sessions) {
        hourCounts[session.entryTime.hour]++;
        if (session.exitTime != null) {
          totalDuration +=
              session.exitTime!.difference(session.entryTime);
        }
      }

      final totalSpots = await (database.select(database.parkingSpots)
            ..where((tbl) => tbl.lotId.equals(lotId)))
          .get();

      final spotCount = totalSpots.length;
      final maxHourCount =
          hourCounts.reduce((a, b) => a > b ? a : b);

      final avgDuration = sessions.isNotEmpty
          ? Duration(
              milliseconds:
                  totalDuration.inMilliseconds ~/ sessions.length,
            )
          : Duration.zero;

      final avgOccupancy = spotCount > 0 && sessions.isNotEmpty
          ? (sessions.length / spotCount) * 100
          : 0.0;

      final peakOccupancy =
          spotCount > 0 ? (maxHourCount / spotCount) * 100 : 0.0;

      final report = OccupancyReport(
        startDate: startDate,
        endDate: endDate,
        averageOccupancy: avgOccupancy,
        peakOccupancy: peakOccupancy,
        averageDuration: avgDuration,
        hourlyBreakdown: List.generate(
          24,
          (hour) => HourlyOccupancy(
            hour: hour,
            occupancyPercentage:
                spotCount > 0 ? (hourCounts[hour] / spotCount) * 100 : 0,
            vehicleCount: hourCounts[hour],
          ),
        ),
      );

      return Right(report);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to generate occupancy report: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getEmployeePerformanceReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final sessionCounts = await localDataSource.getSessionCountByEmployee(
        lotId,
        startDate,
        endDate,
      );

      final result = <Map<String, dynamic>>[];
      for (final entry in sessionCounts.entries) {
        final employee = await (database.select(database.employees)
              ..where((tbl) => tbl.remoteId.equals(entry.key)))
            .getSingleOrNull();

        result.add({
          'employee_id': entry.key,
          'employee_name': employee?.name ?? 'Unknown',
          'sessions_processed': entry.value,
        });
      }

      return Right(result);
    } catch (e) {
      return Left(
        CacheFailure(
            message: 'Failed to generate employee performance report: $e'),
      );
    }
  }
}

class _DailyAccum {

  _DailyAccum({required this.date});
  final DateTime date;
  double revenue = 0;
  int count = 0;
}
