import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/camera_management/domain/entities/camera_device.dart';

abstract class CameraRepository {
  Future<Either<Failure, List<CameraDevice>>> getCameras(String lotId);
  Future<Either<Failure, CameraPairResult>> pairCamera({
    required String cameraUid,
    required String pairingCode,
    required String lotId,
    required String cameraType,
    required String name,
  });
}
