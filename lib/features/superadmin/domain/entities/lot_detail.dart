import 'package:equatable/equatable.dart';

class LotDetail extends Equatable {
  const LotDetail({
    required this.id,
    required this.name,
    this.address,
    required this.timezone,
    required this.createdAt,
    this.spotCount = 0,
    this.occupiedCount = 0,
    this.cameraCount = 0,
    this.employeeCount = 0,
  });

  factory LotDetail.fromJson(Map<String, dynamic> json) {
    return LotDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      createdAt: DateTime.parse(json['created_at'] as String),
      spotCount: json['spot_count'] as int? ?? 0,
      occupiedCount: json['occupied_count'] as int? ?? 0,
      cameraCount: json['camera_count'] as int? ?? 0,
      employeeCount: json['employee_count'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String? address;
  final String timezone;
  final DateTime createdAt;
  final int spotCount;
  final int occupiedCount;
  final int cameraCount;
  final int employeeCount;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (address != null) 'address': address,
        'timezone': timezone,
      };

  @override
  List<Object?> get props => [id, name, address, timezone, createdAt,
        spotCount, occupiedCount, cameraCount, employeeCount];
}

class SpotDetail extends Equatable {
  const SpotDetail({
    required this.id,
    required this.lotId,
    required this.spotNumber,
    required this.size,
    required this.status,
    this.row,
    this.col,
  });

  factory SpotDetail.fromJson(Map<String, dynamic> json) {
    return SpotDetail(
      id: json['id'] as int,
      lotId: json['lot_id'] as String,
      spotNumber: json['spot_number'] as String,
      size: json['size'] as String,
      status: json['status'] as String,
      row: json['row'] as int?,
      col: json['col'] as int?,
    );
  }

  final int id;
  final String lotId;
  final String spotNumber;
  final String size;
  final String status;
  final int? row;
  final int? col;

  @override
  List<Object?> get props => [id, lotId, spotNumber, size, status, row, col];
}

class EmployeeDetail extends Equatable {
  const EmployeeDetail({
    required this.id,
    this.remoteId,
    required this.name,
    required this.email,
    required this.role,
    this.assignedLotId,
    this.assignedLotName,
    required this.isActive,
    required this.createdAt,
  });

  factory EmployeeDetail.fromJson(Map<String, dynamic> json) {
    return EmployeeDetail(
      id: json['id'] as int,
      remoteId: json['remote_id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      assignedLotId: json['assigned_lot_id'] as String?,
      assignedLotName: json['assigned_lot_name'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final String? remoteId;
  final String name;
  final String email;
  final String role;
  final String? assignedLotId;
  final String? assignedLotName;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, email, role, assignedLotId, isActive];
}

class CameraOverviewItem extends Equatable {
  const CameraOverviewItem({
    required this.id,
    required this.cameraUid,
    this.lotId,
    this.lotName,
    required this.name,
    required this.cameraType,
    required this.isPaired,
    required this.isActive,
    this.lastSeenAt,
    required this.createdAt,
  });

  factory CameraOverviewItem.fromJson(Map<String, dynamic> json) {
    return CameraOverviewItem(
      id: json['id'] as int,
      cameraUid: json['camera_uid'] as String,
      lotId: json['lot_id'] as String?,
      lotName: json['lot_name'] as String?,
      name: json['name'] as String,
      cameraType: json['camera_type'] as String,
      isPaired: json['is_paired'] as bool,
      isActive: json['is_active'] as bool,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final String cameraUid;
  final String? lotId;
  final String? lotName;
  final String name;
  final String cameraType;
  final bool isPaired;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, cameraUid, lotId, isPaired, isActive];
}

class CrossLotRevenueReport extends Equatable {
  const CrossLotRevenueReport({
    required this.startDate,
    required this.endDate,
    required this.grandTotalRevenue,
    required this.grandTotalSessions,
    required this.perLot,
  });

  factory CrossLotRevenueReport.fromJson(Map<String, dynamic> json) {
    return CrossLotRevenueReport(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      grandTotalRevenue: (json['grand_total_revenue'] as num).toDouble(),
      grandTotalSessions: json['grand_total_sessions'] as int,
      perLot: (json['per_lot'] as List)
          .map((e) => LotRevenueSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final DateTime startDate;
  final DateTime endDate;
  final double grandTotalRevenue;
  final int grandTotalSessions;
  final List<LotRevenueSummary> perLot;

  @override
  List<Object?> get props => [startDate, endDate, grandTotalRevenue, grandTotalSessions];
}

class LotRevenueSummary extends Equatable {
  const LotRevenueSummary({
    required this.lotId,
    required this.lotName,
    required this.totalRevenue,
    required this.totalSessions,
  });

  factory LotRevenueSummary.fromJson(Map<String, dynamic> json) {
    return LotRevenueSummary(
      lotId: json['lot_id'] as String,
      lotName: json['lot_name'] as String,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalSessions: json['total_sessions'] as int,
    );
  }

  final String lotId;
  final String lotName;
  final double totalRevenue;
  final int totalSessions;

  @override
  List<Object?> get props => [lotId, totalRevenue, totalSessions];
}

class CrossLotOccupancyReport extends Equatable {
  const CrossLotOccupancyReport({
    required this.totalSpots,
    required this.totalOccupied,
    required this.overallRate,
    required this.perLot,
  });

  factory CrossLotOccupancyReport.fromJson(Map<String, dynamic> json) {
    return CrossLotOccupancyReport(
      totalSpots: json['total_spots'] as int,
      totalOccupied: json['total_occupied'] as int,
      overallRate: (json['overall_rate'] as num).toDouble(),
      perLot: (json['per_lot'] as List)
          .map((e) => LotOccupancySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int totalSpots;
  final int totalOccupied;
  final double overallRate;
  final List<LotOccupancySummary> perLot;

  @override
  List<Object?> get props => [totalSpots, totalOccupied, overallRate];
}

class LotOccupancySummary extends Equatable {
  const LotOccupancySummary({
    required this.lotId,
    required this.lotName,
    required this.totalSpots,
    required this.occupiedSpots,
    required this.occupancyRate,
  });

  factory LotOccupancySummary.fromJson(Map<String, dynamic> json) {
    return LotOccupancySummary(
      lotId: json['lot_id'] as String,
      lotName: json['lot_name'] as String,
      totalSpots: json['total_spots'] as int,
      occupiedSpots: json['occupied_spots'] as int,
      occupancyRate: (json['occupancy_rate'] as num).toDouble(),
    );
  }

  final String lotId;
  final String lotName;
  final int totalSpots;
  final int occupiedSpots;
  final double occupancyRate;

  @override
  List<Object?> get props => [lotId, totalSpots, occupiedSpots, occupancyRate];
}
