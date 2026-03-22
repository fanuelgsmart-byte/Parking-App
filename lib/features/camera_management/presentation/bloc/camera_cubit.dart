import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/camera_management/domain/entities/camera_device.dart';
import 'package:parkflow_manager/features/camera_management/domain/repositories/camera_repository.dart';

// -- States --

abstract class CameraState extends Equatable {
  const CameraState();
  @override
  List<Object?> get props => [];
}

class CameraInitial extends CameraState {
  const CameraInitial();
}

class CameraLoading extends CameraState {
  const CameraLoading();
}

class CameraListLoaded extends CameraState {
  const CameraListLoaded({required this.cameras});
  final List<CameraDevice> cameras;
  @override
  List<Object?> get props => [cameras];
}

class CameraPairing extends CameraState {
  const CameraPairing();
}

class CameraPairingSuccess extends CameraState {
  const CameraPairingSuccess({required this.result});
  final CameraPairResult result;
  @override
  List<Object?> get props => [result.camera.id];
}

class CameraError extends CameraState {
  const CameraError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}

// -- Cubit --

@injectable
class CameraCubit extends Cubit<CameraState> {
  CameraCubit({required this.repository}) : super(const CameraInitial());

  final CameraRepository repository;
  String? _currentLotId;

  Future<void> loadCameras(String lotId) async {
    _currentLotId = lotId;
    emit(const CameraLoading());
    final result = await repository.getCameras(lotId);
    result.fold(
      (failure) => emit(CameraError(message: failure.message)),
      (cameras) => emit(CameraListLoaded(cameras: cameras)),
    );
  }

  Future<void> pairCamera({
    required String cameraUid,
    required String pairingCode,
    required String lotId,
    required String cameraType,
    required String name,
  }) async {
    emit(const CameraPairing());
    final result = await repository.pairCamera(
      cameraUid: cameraUid,
      pairingCode: pairingCode,
      lotId: lotId,
      cameraType: cameraType,
      name: name,
    );
    result.fold(
      (failure) => emit(CameraError(message: failure.message)),
      (pairResult) => emit(CameraPairingSuccess(result: pairResult)),
    );
  }

  void reloadCameras() {
    if (_currentLotId != null) {
      loadCameras(_currentLotId!);
    }
  }
}
