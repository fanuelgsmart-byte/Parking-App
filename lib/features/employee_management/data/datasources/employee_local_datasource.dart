import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/features/employee_management/domain/entities/employee.dart';

abstract class EmployeeLocalDataSource {
  Future<List<EmployeeData>> getEmployees(String lotId);
  Future<EmployeeData?> getEmployeeByRemoteId(String remoteId);
  Future<int> insertEmployee(EmployeesCompanion companion);
  Future<void> updateEmployee(String remoteId, EmployeesCompanion companion);
  Future<void> deactivateEmployee(String remoteId);
  Future<void> upsertEmployees(List<Employee> employees);
}

@Injectable(as: EmployeeLocalDataSource)
class EmployeeLocalDataSourceImpl implements EmployeeLocalDataSource {
  final AppDatabase database;

  EmployeeLocalDataSourceImpl({required this.database});

  @override
  Future<List<EmployeeData>> getEmployees(String lotId) {
    return (database.select(database.employees)
          ..where(
            (tbl) =>
                tbl.assignedLotId.equals(lotId) &
                tbl.isActive.equals(true),
          ))
        .get();
  }

  @override
  Future<EmployeeData?> getEmployeeByRemoteId(String remoteId) {
    return (database.select(database.employees)
          ..where((tbl) => tbl.remoteId.equals(remoteId)))
        .getSingleOrNull();
  }

  @override
  Future<int> insertEmployee(EmployeesCompanion companion) {
    return database.into(database.employees).insert(companion);
  }

  @override
  Future<void> updateEmployee(
      String remoteId, EmployeesCompanion companion) async {
    await (database.update(database.employees)
          ..where((tbl) => tbl.remoteId.equals(remoteId)))
        .write(companion);
  }

  @override
  Future<void> deactivateEmployee(String remoteId) async {
    await (database.update(database.employees)
          ..where((tbl) => tbl.remoteId.equals(remoteId)))
        .write(const EmployeesCompanion(isActive: Value(false)));
  }

  @override
  Future<void> upsertEmployees(List<Employee> employees) async {
    for (final employee in employees) {
      final existing = await getEmployeeByRemoteId(employee.id);
      final companion = EmployeesCompanion(
        remoteId: Value(employee.id),
        name: Value(employee.name),
        email: Value(employee.email),
        role: Value(employee.role),
        assignedLotId: Value(employee.assignedLotId),
        isActive: Value(employee.isActive),
      );

      if (existing == null) {
        await database.into(database.employees).insert(companion);
      } else {
        await (database.update(database.employees)
              ..where((tbl) => tbl.remoteId.equals(employee.id)))
            .write(companion);
      }
    }
  }
}
