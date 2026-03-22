import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  const DashboardStats({
    required this.totalLots,
    required this.totalSpots,
    required this.occupiedSpots,
    required this.totalActiveSessions,
    required this.totalRevenueAllTime,
    required this.totalRevenueToday,
    required this.totalEmployees,
    required this.totalCameras,
    required this.activeCameras,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalLots: json['total_lots'] as int,
      totalSpots: json['total_spots'] as int,
      occupiedSpots: json['occupied_spots'] as int,
      totalActiveSessions: json['total_active_sessions'] as int,
      totalRevenueAllTime: (json['total_revenue_all_time'] as num).toDouble(),
      totalRevenueToday: (json['total_revenue_today'] as num).toDouble(),
      totalEmployees: json['total_employees'] as int,
      totalCameras: json['total_cameras'] as int,
      activeCameras: json['active_cameras'] as int,
    );
  }

  final int totalLots;
  final int totalSpots;
  final int occupiedSpots;
  final int totalActiveSessions;
  final double totalRevenueAllTime;
  final double totalRevenueToday;
  final int totalEmployees;
  final int totalCameras;
  final int activeCameras;

  @override
  List<Object?> get props => [
        totalLots, totalSpots, occupiedSpots, totalActiveSessions,
        totalRevenueAllTime, totalRevenueToday, totalEmployees,
        totalCameras, activeCameras,
      ];
}
