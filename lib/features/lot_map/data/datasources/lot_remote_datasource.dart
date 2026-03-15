import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/lot_map/data/models/parking_lot_model.dart';
import 'package:parkflow_manager/features/lot_map/data/models/parking_spot_model.dart';

abstract class LotRemoteDataSource {
  Future<List<ParkingLotModel>> getLots();
  Future<ParkingLotModel> getLotById(String lotId);
  Future<List<ParkingSpotModel>> getSpots(String lotId);
}

@Injectable(as: LotRemoteDataSource)
class LotRemoteDataSourceImpl implements LotRemoteDataSource {
  final ApiClient apiClient;

  LotRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ParkingLotModel>> getLots() async {
    try {
      final response = await apiClient.get(ApiConstants.lots);
      final list = response.data['lots'] as List;
      return list
          .map((e) => ParkingLotModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ParkingLotModel> getLotById(String lotId) async {
    try {
      final response = await apiClient.get('${ApiConstants.lots}/$lotId');
      return ParkingLotModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ParkingSpotModel>> getSpots(String lotId) async {
    try {
      final path = ApiConstants.lotSpots.replaceAll('{id}', lotId);
      final response = await apiClient.get(path);
      final list = response.data['spots'] as List;
      return list
          .map((e) => ParkingSpotModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
