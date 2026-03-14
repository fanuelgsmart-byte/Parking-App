import 'package:freezed_annotation/freezed_annotation.dart';

part 'occupancy_report.freezed.dart';
part 'occupancy_report.g.dart';

@freezed
abstract class OccupancyReport with _$OccupancyReport {
  const factory OccupancyReport({
    required DateTime startDate,
    required DateTime endDate,
    required double averageOccupancy,
    required double peakOccupancy,
    required Duration averageDuration,
    required List<HourlyOccupancy> hourlyBreakdown,
  }) = _OccupancyReport;

  factory OccupancyReport.fromJson(Map<String, dynamic> json) =>
      _$OccupancyReportFromJson(json);
}

@freezed
abstract class HourlyOccupancy with _$HourlyOccupancy {
  const factory HourlyOccupancy({
    required int hour,
    required double occupancyPercentage,
    required int vehicleCount,
  }) = _HourlyOccupancy;

  factory HourlyOccupancy.fromJson(Map<String, dynamic> json) =>
      _$HourlyOccupancyFromJson(json);
}
