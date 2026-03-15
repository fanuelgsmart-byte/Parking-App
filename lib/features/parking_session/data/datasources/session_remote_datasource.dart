import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/parking_session/data/models/parking_session_model.dart';

abstract class SessionRemoteDataSource {
  Future<List<ParkingSessionModel>> getActiveSessions(String lotId);
  Future<ParkingSessionModel> createSession(Map<String, dynamic> data);
  Future<ParkingSessionModel> updateSession(
      int id, Map<String, dynamic> data);
}

@Injectable(as: SessionRemoteDataSource)
class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  final ApiClient apiClient;

  SessionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ParkingSessionModel>> getActiveSessions(String lotId) async {
    try {
      final response = await apiClient.get(
        ApiConstants.activeSessions,
        queryParameters: {'lot_id': lotId},
      );
      final list = response.data['sessions'] as List;
      return list
          .map((e) =>
              ParkingSessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ParkingSessionModel> createSession(
      Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(
        ApiConstants.sessions,
        data: data,
      );
      return ParkingSessionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ParkingSessionModel> updateSession(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put(
        '${ApiConstants.sessions}/$id',
        data: data,
      );
      return ParkingSessionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
