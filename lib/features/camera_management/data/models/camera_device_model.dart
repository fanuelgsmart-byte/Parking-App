import 'package:parkflow_manager/features/camera_management/domain/entities/camera_device.dart';

class CameraDeviceModel {
  const CameraDeviceModel({
    required this.id,
    required this.cameraUid,
    required this.name,
    required this.cameraType,
    required this.isPaired,
    required this.isActive,
    required this.createdAt,
    this.lotId,
    this.lastSeenAt,
    this.apiKey,
  });

  factory CameraDeviceModel.fromJson(Map<String, dynamic> json) {
    return CameraDeviceModel(
      id: json['id'] as int,
      cameraUid: json['camera_uid'] as String,
      lotId: json['lot_id'] as String?,
      name: json['name'] as String? ?? 'Camera',
      cameraType: json['camera_type'] as String? ?? 'entrance',
      isPaired: json['is_paired'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      apiKey: json['api_key'] as String?,
    );
  }

  final int id;
  final String cameraUid;
  final String? lotId;
  final String name;
  final String cameraType;
  final bool isPaired;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final String? apiKey;

  CameraDevice toEntity() => CameraDevice(
        id: id,
        cameraUid: cameraUid,
        lotId: lotId,
        name: name,
        cameraType: cameraType,
        isPaired: isPaired,
        isActive: isActive,
        lastSeenAt: lastSeenAt,
        createdAt: createdAt,
      );

  CameraPairResult toPairResult() => CameraPairResult(
        camera: toEntity(),
        apiKey: apiKey ?? '',
      );
}
