import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/audit_entry.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/dashboard_stats.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';

abstract class SuperadminRemoteDataSource {
  Future<DashboardStats> getDashboard();
  Future<List<LotDetail>> getLots();
  Future<LotDetail> createLot(Map<String, dynamic> data);
  Future<LotDetail> updateLot(String lotId, Map<String, dynamic> data);
  Future<void> deleteLot(String lotId);
  Future<List<SpotDetail>> getSpots(String lotId);
  Future<SpotDetail> createSpot(String lotId, Map<String, dynamic> data);
  Future<SpotDetail> updateSpot(String lotId, int spotId, Map<String, dynamic> data);
  Future<void> deleteSpot(String lotId, int spotId);
  Future<CrossLotRevenueReport> getRevenueReport(DateTime startDate, DateTime endDate);
  Future<CrossLotOccupancyReport> getOccupancyReport();
  Future<List<EmployeeDetail>> getEmployees({String? lotId});
  Future<EmployeeDetail> createEmployee(Map<String, dynamic> data);
  Future<EmployeeDetail> updateEmployee(int id, Map<String, dynamic> data);
  Future<void> deactivateEmployee(int id);
  Future<List<CameraOverviewItem>> getCameras();
  Future<CameraOverviewItem> preRegisterCamera(Map<String, dynamic> data);
  Future<PaginatedAuditLog> getAuditLog({int page = 1, int pageSize = 50, String? action, String? entityType});
}

@Injectable(as: SuperadminRemoteDataSource)
class SuperadminRemoteDataSourceImpl implements SuperadminRemoteDataSource {
  SuperadminRemoteDataSourceImpl({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<DashboardStats> getDashboard() async {
    try {
      final response = await apiClient.get(ApiConstants.superadminDashboard);
      return DashboardStats.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<LotDetail>> getLots() async {
    try {
      final response = await apiClient.get(ApiConstants.superadminLots);
      final list = response.data as List;
      return list.map((e) => LotDetail.fromJson(e as Map<String, dynamic>)).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<LotDetail> createLot(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(ApiConstants.superadminLots, data: data);
      return LotDetail.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<LotDetail> updateLot(String lotId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put('${ApiConstants.superadminLots}/$lotId', data: data);
      return LotDetail.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteLot(String lotId) async {
    try {
      await apiClient.delete('${ApiConstants.superadminLots}/$lotId');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<SpotDetail>> getSpots(String lotId) async {
    try {
      final url = ApiConstants.superadminLotSpots.replaceFirst('{id}', lotId);
      final response = await apiClient.get(url);
      final list = response.data as List;
      return list.map((e) => SpotDetail.fromJson(e as Map<String, dynamic>)).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<SpotDetail> createSpot(String lotId, Map<String, dynamic> data) async {
    try {
      final url = ApiConstants.superadminLotSpots.replaceFirst('{id}', lotId);
      final response = await apiClient.post(url, data: data);
      return SpotDetail.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<SpotDetail> updateSpot(String lotId, int spotId, Map<String, dynamic> data) async {
    try {
      final url = '${ApiConstants.superadminLotSpots.replaceFirst('{id}', lotId)}/$spotId';
      final response = await apiClient.put(url, data: data);
      return SpotDetail.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteSpot(String lotId, int spotId) async {
    try {
      final url = '${ApiConstants.superadminLotSpots.replaceFirst('{id}', lotId)}/$spotId';
      await apiClient.delete(url);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CrossLotRevenueReport> getRevenueReport(DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        ApiConstants.superadminReportsRevenue,
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      return CrossLotRevenueReport.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CrossLotOccupancyReport> getOccupancyReport() async {
    try {
      final response = await apiClient.get(ApiConstants.superadminReportsOccupancy);
      return CrossLotOccupancyReport.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<EmployeeDetail>> getEmployees({String? lotId}) async {
    try {
      final response = await apiClient.get(
        ApiConstants.superadminEmployees,
        queryParameters: lotId != null ? {'lot_id': lotId} : null,
      );
      final list = response.data as List;
      return list.map((e) => EmployeeDetail.fromJson(e as Map<String, dynamic>)).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<EmployeeDetail> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(ApiConstants.superadminEmployees, data: data);
      return EmployeeDetail.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<EmployeeDetail> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put('${ApiConstants.superadminEmployees}/$id', data: data);
      return EmployeeDetail.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deactivateEmployee(int id) async {
    try {
      await apiClient.delete('${ApiConstants.superadminEmployees}/$id');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CameraOverviewItem>> getCameras() async {
    try {
      final response = await apiClient.get(ApiConstants.superadminCameras);
      final list = response.data as List;
      return list.map((e) => CameraOverviewItem.fromJson(e as Map<String, dynamic>)).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CameraOverviewItem> preRegisterCamera(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(ApiConstants.superadminCameraPreRegister, data: data);
      return CameraOverviewItem.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PaginatedAuditLog> getAuditLog({int page = 1, int pageSize = 50, String? action, String? entityType}) async {
    try {
      final params = <String, dynamic>{'page': page, 'page_size': pageSize};
      if (action != null) params['action'] = action;
      if (entityType != null) params['entity_type'] = entityType;
      final response = await apiClient.get(ApiConstants.superadminAuditLog, queryParameters: params);
      return PaginatedAuditLog.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
