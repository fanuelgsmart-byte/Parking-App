import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';

@injectable
class CalculateFee {
  /// Calculates the parking fee based on duration and vehicle-size rate.
  /// Returns the fee in the base currency unit.
  double call({
    required ParkingSession session,
    required double ratePerHour,
  }) {
    final duration = session.duration;
    final hours = duration.inMinutes / 60.0;

    // Minimum charge of 1 hour
    final chargeableHours = hours < 1.0 ? 1.0 : hours;

    // Round up to nearest 15-minute increment
    final roundedHours = (chargeableHours * 4).ceil() / 4.0;

    return roundedHours * ratePerHour;
  }
}
