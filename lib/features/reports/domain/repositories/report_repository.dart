import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/reports/domain/entities/occupancy_report.dart';
import 'package:parkflow_manager/features/reports/domain/entities/revenue_report.dart';

abstract class ReportRepository {
  Future<Either<Failure, RevenueReport>> getRevenueReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, OccupancyReport>> getOccupancyReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>>
      getEmployeePerformanceReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
