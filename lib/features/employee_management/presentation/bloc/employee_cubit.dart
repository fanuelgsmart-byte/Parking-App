import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/employee_management/domain/entities/employee.dart';
import 'package:parkflow_manager/features/employee_management/domain/repositories/employee_repository.dart';

// ──────────────────────────── State ────────────────────────────

abstract class EmployeeState extends Equatable {
  const EmployeeState();

  @override
  List<Object?> get props => [];
}

class EmployeeInitial extends EmployeeState {
  const EmployeeInitial();
}

class EmployeeLoading extends EmployeeState {
  const EmployeeLoading();
}

class EmployeeListLoaded extends EmployeeState {
  final List<Employee> employees;

  const EmployeeListLoaded({required this.employees});

  @override
  List<Object?> get props => [employees];
}

class EmployeeActionSuccess extends EmployeeState {
  final String message;

  const EmployeeActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class ShiftSummaryLoaded extends EmployeeState {
  final ShiftSummary summary;

  const ShiftSummaryLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class EmployeeError extends EmployeeState {
  final String message;

  const EmployeeError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ──────────────────────────── Cubit ────────────────────────────

@injectable
class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository repository;
  String? _currentLotId;

  EmployeeCubit({required this.repository}) : super(const EmployeeInitial());

  Future<void> loadEmployees(String lotId) async {
    _currentLotId = lotId;
    emit(const EmployeeLoading());
    final result = await repository.getEmployees(lotId);
    result.fold(
      (failure) => emit(EmployeeError(message: failure.message)),
      (employees) => emit(EmployeeListLoaded(employees: employees)),
    );
  }

  Future<void> addEmployee(Employee employee) async {
    emit(const EmployeeLoading());
    final result = await repository.addEmployee(employee);
    result.fold(
      (failure) => emit(EmployeeError(message: failure.message)),
      (_) async {
        emit(const EmployeeActionSuccess(message: 'Employee added successfully'));
        if (_currentLotId != null) await loadEmployees(_currentLotId!);
      },
    );
  }

  Future<void> updateEmployee(Employee employee) async {
    emit(const EmployeeLoading());
    final result = await repository.updateEmployee(employee);
    result.fold(
      (failure) => emit(EmployeeError(message: failure.message)),
      (_) async {
        emit(const EmployeeActionSuccess(
            message: 'Employee updated successfully'));
        if (_currentLotId != null) await loadEmployees(_currentLotId!);
      },
    );
  }

  Future<void> deactivateEmployee(String id) async {
    emit(const EmployeeLoading());
    final result = await repository.deactivateEmployee(id);
    result.fold(
      (failure) => emit(EmployeeError(message: failure.message)),
      (_) async {
        emit(const EmployeeActionSuccess(
            message: 'Employee deactivated successfully'));
        if (_currentLotId != null) await loadEmployees(_currentLotId!);
      },
    );
  }

  Future<void> loadShiftSummary(String employeeId, DateTime date) async {
    emit(const EmployeeLoading());
    final result = await repository.getShiftSummary(employeeId, date);
    result.fold(
      (failure) => emit(EmployeeError(message: failure.message)),
      (summary) => emit(ShiftSummaryLoaded(summary: summary)),
    );
  }
}
