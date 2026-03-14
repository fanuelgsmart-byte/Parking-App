import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/employee_management/domain/entities/employee.dart';

abstract class EmployeeRepository {
  Future<Either<Failure, List<Employee>>> getEmployees(String lotId);
  Future<Either<Failure, Employee>> getEmployeeById(String id);
  Future<Either<Failure, Employee>> addEmployee(Employee employee);
  Future<Either<Failure, Employee>> updateEmployee(Employee employee);
  Future<Either<Failure, void>> deactivateEmployee(String id);
  Future<Either<Failure, ShiftSummary>> getShiftSummary(
    String employeeId,
    DateTime date,
  );
}
