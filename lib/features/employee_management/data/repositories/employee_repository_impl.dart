import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/employee_management/data/datasources/employee_local_datasource.dart';
import 'package:parkflow_manager/features/employee_management/data/datasources/employee_remote_datasource.dart';
import 'package:parkflow_manager/features/employee_management/domain/entities/employee.dart';
import 'package:parkflow_manager/features/employee_management/domain/repositories/employee_repository.dart';
import 'package:parkflow_manager/features/parking_session/data/datasources/session_local_datasource.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeLocalDataSource localDataSource;
  final EmployeeRemoteDataSource remoteDataSource;
  final SessionLocalDataSource sessionLocalDataSource;
  final NetworkInfo networkInfo;

  EmployeeRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.sessionLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Employee>>> getEmployees(String lotId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteEmployees = await remoteDataSource.getEmployees(lotId);
        await localDataSource.upsertEmployees(remoteEmployees);
        return Right(remoteEmployees);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.statusCode));
      }
    }

    // Fallback to local
    try {
      final localEmployees = await localDataSource.getEmployees(lotId);
      return Right(
        localEmployees.map((e) => _mapDataToEntity(e)).toList(),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get employees: $e'));
    }
  }

  @override
  Future<Either<Failure, Employee>> getEmployeeById(String id) async {
    try {
      final employeeData = await localDataSource.getEmployeeByRemoteId(id);
      if (employeeData == null) {
        return const Left(CacheFailure(message: 'Employee not found'));
      }
      return Right(_mapDataToEntity(employeeData));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get employee: $e'));
    }
  }

  @override
  Future<Either<Failure, Employee>> addEmployee(Employee employee) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'Internet required to add employee.'),
      );
    }

    try {
      final newEmployee = await remoteDataSource.addEmployee(employee);
      await localDataSource.upsertEmployees([newEmployee]);
      return Right(newEmployee);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Employee>> updateEmployee(Employee employee) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'Internet required to update employee.'),
      );
    }

    try {
      final updated = await remoteDataSource.updateEmployee(employee);
      await localDataSource.upsertEmployees([updated]);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateEmployee(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'Internet required to deactivate employee.'),
      );
    }

    try {
      await remoteDataSource.deactivateEmployee(id);
      await localDataSource.deactivateEmployee(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, ShiftSummary>> getShiftSummary(
    String employeeId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final sessions = await sessionLocalDataSource.getSessionsByDateRange(
        startOfDay,
        endOfDay,
      );

      final employeeSessions = sessions
          .where((s) => s.employeeId == employeeId && s.status == 'completed')
          .toList();

      var cashCollected = 0.0;
      var digitalCollected = 0.0;

      for (final session in employeeSessions) {
        // Simplified — in production fetch from payments table
        cashCollected += session.totalFee ?? 0;
      }

      final summary = ShiftSummary(
        employeeId: employeeId,
        shiftStart: startOfDay,
        shiftEnd: endOfDay,
        vehiclesProcessed: employeeSessions.length,
        cashCollected: cashCollected,
        digitalCollected: digitalCollected,
      );

      return Right(summary);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get shift summary: $e'));
    }
  }

  Employee _mapDataToEntity(dynamic data) {
    return Employee(
      id: data.remoteId as String,
      name: data.name as String,
      email: data.email as String,
      role: data.role as String,
      assignedLotId: data.assignedLotId as String?,
      isActive: data.isActive as bool,
      createdAt: data.createdAt as DateTime,
    );
  }
}
