import 'package:freezed_annotation/freezed_annotation.dart';

part 'parking_lot.freezed.dart';
part 'parking_lot.g.dart';

@freezed
abstract class ParkingLot with _$ParkingLot {
  const factory ParkingLot({
    required String id,
    required String name,
    required String address,
    required int totalSpots,
    required int availableSpots,
    required int rows,
    required int columns,
  }) = _ParkingLot;

  factory ParkingLot.fromJson(Map<String, dynamic> json) =>
      _$ParkingLotFromJson(json);
}

extension ParkingLotX on ParkingLot {
  double get occupancyPercentage =>
      ((totalSpots - availableSpots) / totalSpots) * 100;

  bool get isFull => availableSpots == 0;
}
