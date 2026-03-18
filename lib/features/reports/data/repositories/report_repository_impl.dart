import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/reports/data/datasources/report_local_datasource.dart';
import 'package:parkflow_manager/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:parkflow_manager/features/reports/domain/entities/occupancy_report.dart';
import 'package:parkflow_manager/features/reports/domain/entities/report_payload.dart';
import 'package:parkflow_manager/features/reports/domain/entities/revenue_report.dart';
import 'package:parkflow_manager/features/reports/domain/repositories/report_repository.dart';

@Injectable(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReportLocalDataSource localDataSource;
  final ReportRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, ReportPayload<RevenueReport>>> getRevenueReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final cacheKey = _cacheKey('revenue', lotId, startDate, endDate);
    if (await networkInfo.isConnected) {
      try {
        final remote = await remoteDataSource.getRevenueReport(
          lotId,
          startDate,
          endDate,
        );
        final report = RevenueReport.fromJson(remote);
        await localDataSource.cacheReport(cacheKey, jsonEncode(report.toJson()));
        return Right(ReportPayload(data: report, isStale: false));
      } catch (e) {
        final cached = await _getCachedRevenue(cacheKey);
        if (cached != null) return Right(cached);
        return Left(
          ServerFailure(
            message:
                'Unable to fetch revenue report from server and no cached report is available: $e',
          ),
        );
      }
    }

    final cached = await _getCachedRevenue(cacheKey);
    if (cached != null) return Right(cached);

    return const Left(
      NetworkFailure(
        message:
            'No connection and no cached revenue report available. Connect to refresh reports.',
      ),
    );
  }

  @override
  Future<Either<Failure, ReportPayload<OccupancyReport>>> getOccupancyReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final cacheKey = _cacheKey('occupancy', lotId, startDate, endDate);
    if (await networkInfo.isConnected) {
      try {
        final remote = await remoteDataSource.getOccupancyReport(
          lotId,
          startDate,
          endDate,
        );
        final report = OccupancyReport.fromJson(remote);
        await localDataSource.cacheReport(cacheKey, jsonEncode(report.toJson()));
        return Right(ReportPayload(data: report, isStale: false));
      } catch (e) {
        final cached = await _getCachedOccupancy(cacheKey);
        if (cached != null) return Right(cached);
        return Left(
          ServerFailure(
            message:
                'Unable to fetch occupancy report from server and no cached report is available: $e',
          ),
        );
      }
    }

    final cached = await _getCachedOccupancy(cacheKey);
    if (cached != null) return Right(cached);

    return const Left(
      NetworkFailure(
        message:
            'No connection and no cached occupancy report available. Connect to refresh reports.',
      ),
    );
  }

  @override
  Future<Either<Failure, ReportPayload<List<Map<String, dynamic>>>>> getEmployeePerformanceReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final cacheKey = _cacheKey('employees', lotId, startDate, endDate);
    if (await networkInfo.isConnected) {
      try {
        final remote = await remoteDataSource.getEmployeePerformance(
          lotId,
          startDate,
          endDate,
        );
        await localDataSource.cacheReport(cacheKey, jsonEncode(remote));
        return Right(ReportPayload(data: remote, isStale: false));
      } catch (e) {
        final cached = await _getCachedEmployeePerformance(cacheKey);
        if (cached != null) return Right(cached);
        return Left(
          ServerFailure(
            message:
                'Unable to fetch employee report from server and no cached report is available: $e',
          ),
        );
      }
    }

    final cached = await _getCachedEmployeePerformance(cacheKey);
    if (cached != null) return Right(cached);

    return const Left(
      NetworkFailure(
        message:
            'No connection and no cached employee report available. Connect to refresh reports.',
      ),
    );
  }

  Future<ReportPayload<RevenueReport>?> _getCachedRevenue(String cacheKey) async {
    final cache = await localDataSource.getCachedReport(cacheKey);
    if (cache == null) return null;
    return ReportPayload(
      data:
          RevenueReport.fromJson(jsonDecode(cache.payload) as Map<String, dynamic>),
      isStale: true,
      cachedAt: cache.cachedAt,
    );
  }

  Future<ReportPayload<OccupancyReport>?> _getCachedOccupancy(
    String cacheKey,
  ) async {
    final cache = await localDataSource.getCachedReport(cacheKey);
    if (cache == null) return null;
    return ReportPayload(
      data: OccupancyReport.fromJson(
        jsonDecode(cache.payload) as Map<String, dynamic>,
      ),
      isStale: true,
      cachedAt: cache.cachedAt,
    );
  }

  Future<ReportPayload<List<Map<String, dynamic>>>?> _getCachedEmployeePerformance(
    String cacheKey,
  ) async {
    final cache = await localDataSource.getCachedReport(cacheKey);
    if (cache == null) return null;
    final decoded = (jsonDecode(cache.payload) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return ReportPayload(
      data: decoded,
      isStale: true,
      cachedAt: cache.cachedAt,
    );
  }

  String _cacheKey(String prefix, String lotId, DateTime start, DateTime end) {
    return '$prefix:$lotId:${start.toIso8601String()}:${end.toIso8601String()}';
  }
}
