import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';

class VehicleModel {

  const VehicleModel({
    required this.id,
    required this.licensePlate,
    required this.size,
    required this.color,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int,
      licensePlate: json['license_plate'] as String,
      size: json['size'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  final int id;
  final String licensePlate;
  final String size;
  final String color;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'license_plate': licensePlate,
      'size': size,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Vehicle toEntity() {
    return Vehicle(
      id: id,
      licensePlate: licensePlate,
      size: VehicleSize.values.firstWhere(
        (e) => e.name == size,
        orElse: () => VehicleSize.medium,
      ),
      color: color,
      createdAt: createdAt,
    );
  }
}
