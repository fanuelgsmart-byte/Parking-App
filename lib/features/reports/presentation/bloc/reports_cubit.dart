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

  const RevenueReportLoaded({required this.report});
  final RevenueReport report;

  @override
  List<Object?> get props => [report];
}

class OccupancyReportLoaded extends ReportsState {

  const OccupancyReportLoaded({required this.report});
  final OccupancyReport report;

  @override
  List<Object?> get props => [report];
}

class EmployeePerformanceLoaded extends ReportsState {

  const EmployeePerformanceLoaded({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  List<Object?> get props => [data];
}

class ReportsError extends ReportsState {

  const ReportsError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

// ──────────────────────────── Cubit ────────────────────────────

@injectable
class ReportsCubit extends Cubit<ReportsState> {

  ReportsCubit({required this.reportRepository})
      : super(const ReportsInitial());
  final ReportRepository reportRepository;

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
