import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/reports/domain/entities/occupancy_report.dart';
import 'package:parkflow_manager/features/reports/domain/entities/report_payload.dart';
import 'package:parkflow_manager/features/reports/domain/entities/revenue_report.dart';
import 'package:parkflow_manager/features/reports/domain/repositories/report_repository.dart';

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
  const RevenueReportLoaded({required this.payload});

  final ReportPayload<RevenueReport> payload;

  RevenueReport get report => payload.data;
  bool get isStale => payload.isStale;

  @override
  List<Object?> get props => [payload];
}

class OccupancyReportLoaded extends ReportsState {
  const OccupancyReportLoaded({required this.payload});

  final ReportPayload<OccupancyReport> payload;

  OccupancyReport get report => payload.data;
  bool get isStale => payload.isStale;

  @override
  List<Object?> get props => [payload];
}

class EmployeePerformanceLoaded extends ReportsState {
  const EmployeePerformanceLoaded({required this.payload});

  final ReportPayload<List<Map<String, dynamic>>> payload;

  List<Map<String, dynamic>> get data => payload.data;
  bool get isStale => payload.isStale;

  @override
  List<Object?> get props => [payload];
}

class ReportsError extends ReportsState {
  const ReportsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

@injectable
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({required this.reportRepository}) : super(const ReportsInitial());

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
      (payload) => emit(RevenueReportLoaded(payload: payload)),
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
      (payload) => emit(OccupancyReportLoaded(payload: payload)),
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
      (payload) => emit(EmployeePerformanceLoaded(payload: payload)),
    );
  }
}
