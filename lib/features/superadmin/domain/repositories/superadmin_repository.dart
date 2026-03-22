import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/audit_entry.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/dashboard_stats.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';

abstract class SuperadminRepository {
  // Dashboard
  Future<Either<Failure, DashboardStats>> getDashboard();

  // Lots
  Future<Either<Failure, List<LotDetail>>> getLots();
  Future<Either<Failure, LotDetail>> createLot({
    required String name,
    String? address,
    String timezone,
  });
  Future<Either<Failure, LotDetail>> updateLot(String lotId, {String? name, String? address, String? timezone});
  Future<Either<Failure, void>> deleteLot(String lotId);

  // Spots
  Future<Either<Failure, List<SpotDetail>>> getSpots(String lotId);
  Future<Either<Failure, SpotDetail>> createSpot(String lotId, {
    required String spotNumber,
    required String size,
    int? row,
    int? col,
  });
  Future<Either<Failure, SpotDetail>> updateSpot(String lotId, int spotId, {String? spotNumber, String? size, int? row, int? col});
  Future<Either<Failure, void>> deleteSpot(String lotId, int spotId);

  // Reports
  Future<Either<Failure, CrossLotRevenueReport>> getRevenueReport(DateTime startDate, DateTime endDate);
  Future<Either<Failure, CrossLotOccupancyReport>> getOccupancyReport();

  // Employees
  Future<Either<Failure, List<EmployeeDetail>>> getEmployees({String? lotId});
  Future<Either<Failure, EmployeeDetail>> createEmployee({
    required String name,
    required String email,
    required String password,
    String role,
    String? assignedLotId,
  });
  Future<Either<Failure, EmployeeDetail>> updateEmployee(int id, {String? name, String? email, String? role, String? assignedLotId, bool? isActive});
  Future<Either<Failure, void>> deactivateEmployee(int id);

  // Cameras
  Future<Either<Failure, List<CameraOverviewItem>>> getCameras();
  Future<Either<Failure, CameraOverviewItem>> preRegisterCamera({required String cameraUid, required String pairingCode});

  // Audit Log
  Future<Either<Failure, PaginatedAuditLog>> getAuditLog({int page, int pageSize, String? action, String? entityType});
}
