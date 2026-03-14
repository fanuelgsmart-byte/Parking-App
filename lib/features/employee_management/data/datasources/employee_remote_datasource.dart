import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/employee_management/domain/entities/employee.dart';

abstract class EmployeeRemoteDataSource {
  Future<List<Employee>> getEmployees(String lotId);
  Future<Employee> addEmployee(Employee employee);
  Future<Employee> updateEmployee(Employee employee);
  Future<void> deactivateEmployee(String id);
}

@Injectable(as: EmployeeRemoteDataSource)
class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  final ApiClient apiClient;

  EmployeeRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<Employee>> getEmployees(String lotId) async {
    try {
      final response = await apiClient.get(
        ApiConstants.employees,
        queryParameters: {'lot_id': lotId},
      );
      final list = response.data['employees'] as List;
      return list
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Employee> addEmployee(Employee employee) async {
    try {
      final response = await apiClient.post(
        ApiConstants.employees,
        data: employee.toJson(),
      );
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    try {
      final response = await apiClient.put(
        '${ApiConstants.employees}/${employee.id}',
        data: employee.toJson(),
      );
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deactivateEmployee(String id) async {
    try {
      await apiClient.delete('${ApiConstants.employees}/$id');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
