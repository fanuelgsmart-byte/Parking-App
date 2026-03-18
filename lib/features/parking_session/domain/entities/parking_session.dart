import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';

part 'parking_session.freezed.dart';
part 'parking_session.g.dart';

@freezed
abstract class ParkingSession with _$ParkingSession {
  const factory ParkingSession({
    required int id,
    required Vehicle vehicle,
    required int spotId,
    required String spotNumber,
    required String lotId,
    required DateTime entryTime,
    DateTime? exitTime,
    double? totalFee,
    required SessionStatus status,
    required String employeeId,
    required bool isSynced,
  }) = _ParkingSession;

  factory ParkingSession.fromJson(Map<String, dynamic> json) =>
      _$ParkingSessionFromJson(json);
}

enum SessionStatus {
  active,
  flaggedForCheckout,
  paymentPending,
  completed;

  String get displayName {
    switch (this) {
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.flaggedForCheckout:
        return 'Ready for Checkout';
      case SessionStatus.paymentPending:
        return 'Payment Pending';
      case SessionStatus.completed:
        return 'Completed';
    }
  }

  bool get isOpen => this != SessionStatus.completed;

  bool canTransitionTo(SessionStatus next) {
    switch (this) {
      case SessionStatus.active:
        return next == SessionStatus.flaggedForCheckout;
      case SessionStatus.flaggedForCheckout:
        return next == SessionStatus.paymentPending ||
            next == SessionStatus.completed;
      case SessionStatus.paymentPending:
        return next == SessionStatus.completed ||
            next == SessionStatus.flaggedForCheckout;
      case SessionStatus.completed:
        return false;
    }
  }
}

extension ParkingSessionX on ParkingSession {
  Duration get duration {
    final end = exitTime ?? DateTime.now();
    return end.difference(entryTime);
  }

  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
