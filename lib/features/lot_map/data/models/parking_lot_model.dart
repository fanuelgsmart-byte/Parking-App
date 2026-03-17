import 'package:parkflow_manager/features/lot_map/domain/entities/parking_lot.dart';

class ParkingLotModel {

  const ParkingLotModel({
    required this.id,
    required this.name,
    required this.address,
    required this.totalSpots,
    required this.availableSpots,
    required this.rows,
    required this.columns,
  });

  factory ParkingLotModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      totalSpots: json['total_spots'] as int,
      availableSpots: json['available_spots'] as int,
      rows: json['rows'] as int,
      columns: json['columns'] as int,
    );
  }
  final String id;
  final String name;
  final String address;
  final int totalSpots;
  final int availableSpots;
  final int rows;
  final int columns;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'total_spots': totalSpots,
      'available_spots': availableSpots,
      'rows': rows,
      'columns': columns,
    };
  }

  ParkingLot toEntity() {
    return ParkingLot(
      id: id,
      name: name,
      address: address,
      totalSpots: totalSpots,
      availableSpots: availableSpots,
      rows: rows,
      columns: columns,
    );
  }
}
