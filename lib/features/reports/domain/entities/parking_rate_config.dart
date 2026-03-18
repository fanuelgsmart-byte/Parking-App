import 'package:equatable/equatable.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';

class ParkingRateConfig extends Equatable {
  const ParkingRateConfig({
    required this.id,
    required this.lotId,
    required this.vehicleSize,
    required this.ratePerHour,
    required this.effectiveFrom,
    required this.isActive,
    this.effectiveTo,
  });

  final int id;
  final String lotId;
  final VehicleSize vehicleSize;
  final double ratePerHour;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;

  @override
  List<Object?> get props => [
        id,
        lotId,
        vehicleSize,
        ratePerHour,
        effectiveFrom,
        effectiveTo,
        isActive,
      ];
}
