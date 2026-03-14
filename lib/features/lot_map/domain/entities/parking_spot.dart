import 'package:freezed_annotation/freezed_annotation.dart';

part 'parking_spot.freezed.dart';
part 'parking_spot.g.dart';

@freezed
abstract class ParkingSpot with _$ParkingSpot {
  const factory ParkingSpot({
    required int id,
    required String spotNumber,
    required String lotId,
    required SpotStatus status,
    required String size,
    int? row,
    int? col,
    String? occupyingPlate,
  }) = _ParkingSpot;

  factory ParkingSpot.fromJson(Map<String, dynamic> json) =>
      _$ParkingSpotFromJson(json);
}

enum SpotStatus {
  available,
  occupied,
  reserved;

  String get displayName {
    switch (this) {
      case SpotStatus.available:
        return 'Available';
      case SpotStatus.occupied:
        return 'Occupied';
      case SpotStatus.reserved:
        return 'Reserved';
    }
  }
}
