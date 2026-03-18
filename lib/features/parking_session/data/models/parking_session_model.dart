import 'package:parkflow_manager/features/parking_session/data/models/vehicle_model.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';

class ParkingSessionModel {
  const ParkingSessionModel({
    required this.id,
    required this.vehicle,
    required this.spotId,
    required this.spotNumber,
    required this.lotId,
    required this.entryTime,
    this.exitTime,
    this.totalFee,
    required this.status,
    required this.employeeId,
    required this.isSynced,
  });

  factory ParkingSessionModel.fromJson(Map<String, dynamic> json) {
    return ParkingSessionModel(
      id: json['id'] as int,
      vehicle: VehicleModel.fromJson(
        json['vehicle'] as Map<String, dynamic>,
      ),
      spotId: json['spot_id'] as int,
      spotNumber: json['spot_number'] as String,
      lotId: json['lot_id'] as String,
      entryTime: DateTime.parse(json['entry_time'] as String),
      exitTime: json['exit_time'] != null
          ? DateTime.parse(json['exit_time'] as String)
          : null,
      totalFee: (json['total_fee'] as num?)?.toDouble(),
      status: json['status'] as String,
      employeeId: json['employee_id'] as String,
      isSynced: json['is_synced'] as bool? ?? true,
    );
  }

  final int id;
  final VehicleModel vehicle;
  final int spotId;
  final String spotNumber;
  final String lotId;
  final DateTime entryTime;
  final DateTime? exitTime;
  final double? totalFee;
  final String status;
  final String employeeId;
  final bool isSynced;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle': vehicle.toJson(),
      'spot_id': spotId,
      'spot_number': spotNumber,
      'lot_id': lotId,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'total_fee': totalFee,
      'status': status,
      'employee_id': employeeId,
      'is_synced': isSynced,
    };
  }

  ParkingSession toEntity() {
    return ParkingSession(
      id: id,
      vehicle: vehicle.toEntity(),
      spotId: spotId,
      spotNumber: spotNumber,
      lotId: lotId,
      entryTime: entryTime,
      exitTime: exitTime,
      totalFee: totalFee,
      status: parseStatus(status),
      employeeId: employeeId,
      isSynced: isSynced,
    );
  }

  static SessionStatus parseStatus(String status) {
    switch (status) {
      case 'active':
        return SessionStatus.active;
      case 'flagged_for_checkout':
        return SessionStatus.flaggedForCheckout;
      case 'payment_pending':
        return SessionStatus.paymentPending;
      case 'completed':
        return SessionStatus.completed;
      default:
        return SessionStatus.active;
    }
  }

  static String statusToString(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return 'active';
      case SessionStatus.flaggedForCheckout:
        return 'flagged_for_checkout';
      case SessionStatus.paymentPending:
        return 'payment_pending';
      case SessionStatus.completed:
        return 'completed';
    }
  }
}
