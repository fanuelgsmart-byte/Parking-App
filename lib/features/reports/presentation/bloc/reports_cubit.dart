import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/reports/domain/entities/occupancy_report.dart';
import 'package:parkflow_manager/features/reports/domain/entities/revenue_report.dart';
import 'package:parkflow_manager/features/reports/domain/repositories/report_repository.dart';

// ──────────────────────────── State ────────────────────────────

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class RevenueReportLoaded extends ReportsState {
  final RevenueReport report;

  const RevenueReportLoaded({required this.report});

  @override
  List<Object?> get props => [report];
}

class OccupancyReportLoaded extends ReportsState {
  final OccupancyReport report;

  const OccupancyReportLoaded({required this.report});

  @override
  List<Object?> get props => [report];
}

class EmployeePerformanceLoaded extends ReportsState {
  final List<Map<String, dynamic>> data;

  const EmployeePerformanceLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ──────────────────────────── Cubit ────────────────────────────

@injectable
class ReportsCubit extends Cubit<ReportsState> {
  final ReportRepository reportRepository;

  ReportsCubit({required this.reportRepository})
      : super(const ReportsInitial());

  Future<void> loadRevenueReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(const ReportsLoading());
    final result = await reportRepository.getRevenueReport(
      lotId: lotId,
      startDate: startDate,
      endDate: endDate,
    );
    result.fold(
      (failure) => emit(ReportsError(message: failure.message)),
      (report) => emit(RevenueReportLoaded(report: report)),
    );
  }

  Future<void> loadOccupancyReport({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(const ReportsLoading());
    final result = await reportRepository.getOccupancyReport(
      lotId: lotId,
      startDate: startDate,
      endDate: endDate,
    );
    result.fold(
      (failure) => emit(ReportsError(message: failure.message)),
      (report) => emit(OccupancyReportLoaded(report: report)),
    );
  }

  Future<void> loadEmployeePerformance({
    required String lotId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(const ReportsLoading());
    final result = await reportRepository.getEmployeePerformanceReport(
      lotId: lotId,
      startDate: startDate,
      endDate: endDate,
    );
    result.fold(
      (failure) => emit(ReportsError(message: failure.message)),
      (data) => emit(EmployeePerformanceLoaded(data: data)),
    );
  }
}
