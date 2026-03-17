import 'package:parkflow_manager/features/lot_map/domain/entities/parking_spot.dart';

class ParkingSpotModel {

  const ParkingSpotModel({
    required this.id,
    required this.spotNumber,
    required this.lotId,
    required this.status,
    required this.size,
    this.row,
    this.col,
    this.occupyingPlate,
  });

  factory ParkingSpotModel.fromJson(Map<String, dynamic> json) {
    return ParkingSpotModel(
      id: json['id'] as int,
      spotNumber: json['spot_number'] as String,
      lotId: json['lot_id'] as String,
      status: json['status'] as String,
      size: json['size'] as String,
      row: json['row'] as int?,
      col: json['col'] as int?,
      occupyingPlate: json['occupying_plate'] as String?,
    );
  }
  final int id;
  final String spotNumber;
  final String lotId;
  final String status;
  final String size;
  final int? row;
  final int? col;
  final String? occupyingPlate;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spot_number': spotNumber,
      'lot_id': lotId,
      'status': status,
      'size': size,
      'row': row,
      'col': col,
      'occupying_plate': occupyingPlate,
    };
  }

  ParkingSpot toEntity() {
    return ParkingSpot(
      id: id,
      spotNumber: spotNumber,
      lotId: lotId,
      status: _parseStatus(status),
      size: size,
      row: row,
      col: col,
      occupyingPlate: occupyingPlate,
    );
  }

  static SpotStatus _parseStatus(String status) {
    switch (status) {
      case 'available':
        return SpotStatus.available;
      case 'occupied':
        return SpotStatus.occupied;
      case 'reserved':
        return SpotStatus.reserved;
      default:
        return SpotStatus.available;
    }
  }
}
