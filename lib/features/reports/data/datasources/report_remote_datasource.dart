import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';

abstract class ReportRemoteDataSource {
  Future<Map<String, dynamic>> getRevenueReport(
    String lotId,
    DateTime start,
    DateTime end,
  );

  Future<Map<String, dynamic>> getOccupancyReport(
    String lotId,
    DateTime start,
    DateTime end,
  );

  Future<List<Map<String, dynamic>>> getEmployeePerformance(
    String lotId,
    DateTime start,
    DateTime end,
  );
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final ApiClient apiClient;

  ReportRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getRevenueReport(
    String lotId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await apiClient.get(
        ApiConstants.reportsRevenue,
        queryParameters: {
          'lot_id': lotId,
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getOccupancyReport(
    String lotId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await apiClient.get(
        ApiConstants.reportsOccupancy,
        queryParameters: {
          'lot_id': lotId,
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEmployeePerformance(
    String lotId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await apiClient.get(
        ApiConstants.reportsEmployeePerformance,
        queryParameters: {
          'lot_id': lotId,
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      return (response.data['employees'] as List)
          .cast<Map<String, dynamic>>();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
