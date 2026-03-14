import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee.freezed.dart';
part 'employee.g.dart';

@freezed
abstract class Employee with _$Employee {
  const factory Employee({
    required String id,
    required String name,
    required String email,
    required String role,
    String? assignedLotId,
    required bool isActive,
    required DateTime createdAt,
  }) = _Employee;

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
}

@freezed
abstract class ShiftSummary with _$ShiftSummary {
  const factory ShiftSummary({
    required String employeeId,
    required DateTime shiftStart,
    required DateTime shiftEnd,
    required int vehiclesProcessed,
    required double cashCollected,
    required double digitalCollected,
    String? notes,
  }) = _ShiftSummary;

  factory ShiftSummary.fromJson(Map<String, dynamic> json) =>
      _$ShiftSummaryFromJson(json);
}
