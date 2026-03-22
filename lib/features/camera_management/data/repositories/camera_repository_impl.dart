import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/camera_management/data/datasources/camera_remote_datasource.dart';
import 'package:parkflow_manager/features/camera_management/domain/entities/camera_device.dart';
import 'package:parkflow_manager/features/camera_management/domain/repositories/camera_repository.dart';

@Injectable(as: CameraRepository)
class CameraRepositoryImpl implements CameraRepository {
  CameraRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CameraRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, List<CameraDevice>>> getCameras(String lotId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final models = await remoteDataSource.getCameras(lotId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CameraPairResult>> pairCamera({
    required String cameraUid,
    required String pairingCode,
    required String lotId,
    required String cameraType,
    required String name,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = await remoteDataSource.pairCamera(
        cameraUid: cameraUid,
        pairingCode: pairingCode,
        lotId: lotId,
        cameraType: cameraType,
        name: name,
      );
      return Right(model.toPairResult());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }
}
