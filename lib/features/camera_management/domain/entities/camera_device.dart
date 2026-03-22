import 'package:equatable/equatable.dart';

class CameraDevice extends Equatable {
  const CameraDevice({
    required this.id,
    required this.cameraUid,
    required this.name,
    required this.cameraType,
    required this.isPaired,
    required this.isActive,
    required this.createdAt,
    this.lotId,
    this.lastSeenAt,
  });

  final int id;
  final String cameraUid;
  final String? lotId;
  final String name;
  final String cameraType; // "entrance" or "exit"
  final bool isPaired;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, cameraUid, lotId, name, cameraType, isPaired, isActive, lastSeenAt, createdAt];
}

class CameraPairResult {
  const CameraPairResult({
    required this.camera,
    required this.apiKey,
  });

  final CameraDevice camera;
  final String apiKey;
}
