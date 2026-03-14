import 'package:freezed_annotation/freezed_annotation.dart';

part 'revenue_report.freezed.dart';
part 'revenue_report.g.dart';

@freezed
abstract class RevenueReport with _$RevenueReport {
  const factory RevenueReport({
    required DateTime startDate,
    required DateTime endDate,
    required double totalRevenue,
    required double cashRevenue,
    required double digitalRevenue,
    required int totalSessions,
    required List<DailyRevenue> dailyBreakdown,
    required Map<String, double> revenueByVehicleSize,
  }) = _RevenueReport;

  factory RevenueReport.fromJson(Map<String, dynamic> json) =>
      _$RevenueReportFromJson(json);
}

@freezed
abstract class DailyRevenue with _$DailyRevenue {
  const factory DailyRevenue({
    required DateTime date,
    required double revenue,
    required int sessionCount,
  }) = _DailyRevenue;

  factory DailyRevenue.fromJson(Map<String, dynamic> json) =>
      _$DailyRevenueFromJson(json);
}
