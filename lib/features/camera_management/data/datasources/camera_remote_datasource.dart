import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/camera_management/data/models/camera_device_model.dart';

abstract class CameraRemoteDataSource {
  Future<List<CameraDeviceModel>> getCameras(String lotId);
  Future<CameraDeviceModel> pairCamera({
    required String cameraUid,
    required String pairingCode,
    required String lotId,
    required String cameraType,
    required String name,
  });
}

@Injectable(as: CameraRemoteDataSource)
class CameraRemoteDataSourceImpl implements CameraRemoteDataSource {
  CameraRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<CameraDeviceModel>> getCameras(String lotId) async {
    try {
      final response = await apiClient.get(
        ApiConstants.cameraDevices,
        queryParameters: {'lot_id': lotId},
      );
      final list = response.data as List;
      return list
          .map((e) => CameraDeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CameraDeviceModel> pairCamera({
    required String cameraUid,
    required String pairingCode,
    required String lotId,
    required String cameraType,
    required String name,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.cameraPair,
        data: {
          'camera_uid': cameraUid,
          'pairing_code': pairingCode,
          'lot_id': lotId,
          'camera_type': cameraType,
          'name': name,
        },
      );
      return CameraDeviceModel.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
