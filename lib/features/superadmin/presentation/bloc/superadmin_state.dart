import 'package:equatable/equatable.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/audit_entry.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/dashboard_stats.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';

abstract class SuperadminState extends Equatable {
  const SuperadminState();

  @override
  List<Object?> get props => [];
}

class SuperadminInitial extends SuperadminState {
  const SuperadminInitial();
}

class SuperadminLoading extends SuperadminState {
  const SuperadminLoading();
}

class SuperadminDashboardLoaded extends SuperadminState {
  const SuperadminDashboardLoaded({required this.stats});
  final DashboardStats stats;

  @override
  List<Object?> get props => [stats];
}

class SuperadminLotsLoaded extends SuperadminState {
  const SuperadminLotsLoaded({required this.lots});
  final List<LotDetail> lots;

  @override
  List<Object?> get props => [lots];
}

class SuperadminSpotsLoaded extends SuperadminState {
  const SuperadminSpotsLoaded({required this.spots, required this.lotId});
  final List<SpotDetail> spots;
  final String lotId;

  @override
  List<Object?> get props => [spots, lotId];
}

class SuperadminEmployeesLoaded extends SuperadminState {
  const SuperadminEmployeesLoaded({required this.employees, required this.lots});
  final List<EmployeeDetail> employees;
  final List<LotDetail> lots;

  @override
  List<Object?> get props => [employees, lots];
}

class SuperadminCamerasLoaded extends SuperadminState {
  const SuperadminCamerasLoaded({required this.cameras});
  final List<CameraOverviewItem> cameras;

  @override
  List<Object?> get props => [cameras];
}

class SuperadminRevenueLoaded extends SuperadminState {
  const SuperadminRevenueLoaded({required this.report});
  final CrossLotRevenueReport report;

  @override
  List<Object?> get props => [report];
}

class SuperadminOccupancyLoaded extends SuperadminState {
  const SuperadminOccupancyLoaded({required this.report});
  final CrossLotOccupancyReport report;

  @override
  List<Object?> get props => [report];
}

class SuperadminAuditLogLoaded extends SuperadminState {
  const SuperadminAuditLogLoaded({required this.auditLog});
  final PaginatedAuditLog auditLog;

  @override
  List<Object?> get props => [auditLog];
}

class SuperadminActionSuccess extends SuperadminState {
  const SuperadminActionSuccess({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class SuperadminError extends SuperadminState {
  const SuperadminError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
