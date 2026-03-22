import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle.freezed.dart';
part 'vehicle.g.dart';

@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({
    required int id,
    required String licensePlate,
    required VehicleSize size,
    required String color,
    required DateTime createdAt,
    String? imageUrl,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
}

enum VehicleSize {
  small,
  medium,
  large;

  String get displayName {
    switch (this) {
      case VehicleSize.small:
        return 'Small';
      case VehicleSize.medium:
        return 'Medium';
      case VehicleSize.large:
        return 'Large';
    }
  }
}
