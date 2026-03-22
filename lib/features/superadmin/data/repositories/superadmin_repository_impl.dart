import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/superadmin/data/datasources/superadmin_remote_datasource.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/audit_entry.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/dashboard_stats.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';
import 'package:parkflow_manager/features/superadmin/domain/repositories/superadmin_repository.dart';

@Injectable(as: SuperadminRepository)
class SuperadminRepositoryImpl implements SuperadminRepository {
  SuperadminRepositoryImpl({required this.remoteDataSource});
  final SuperadminRemoteDataSource remoteDataSource;

  Future<Either<Failure, T>> _call<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DashboardStats>> getDashboard() => _call(() => remoteDataSource.getDashboard());

  @override
  Future<Either<Failure, List<LotDetail>>> getLots() => _call(() => remoteDataSource.getLots());

  @override
  Future<Either<Failure, LotDetail>> createLot({required String name, String? address, String timezone = 'UTC'}) =>
      _call(() => remoteDataSource.createLot({'name': name, if (address != null) 'address': address, 'timezone': timezone}));

  @override
  Future<Either<Failure, LotDetail>> updateLot(String lotId, {String? name, String? address, String? timezone}) =>
      _call(() => remoteDataSource.updateLot(lotId, {
            if (name != null) 'name': name,
            if (address != null) 'address': address,
            if (timezone != null) 'timezone': timezone,
          }));

  @override
  Future<Either<Failure, void>> deleteLot(String lotId) => _call(() => remoteDataSource.deleteLot(lotId));

  @override
  Future<Either<Failure, List<SpotDetail>>> getSpots(String lotId) => _call(() => remoteDataSource.getSpots(lotId));

  @override
  Future<Either<Failure, SpotDetail>> createSpot(String lotId, {required String spotNumber, required String size, int? row, int? col}) =>
      _call(() => remoteDataSource.createSpot(lotId, {
            'spot_number': spotNumber,
            'size': size,
            if (row != null) 'row': row,
            if (col != null) 'col': col,
          }));

  @override
  Future<Either<Failure, SpotDetail>> updateSpot(String lotId, int spotId, {String? spotNumber, String? size, int? row, int? col}) =>
      _call(() => remoteDataSource.updateSpot(lotId, spotId, {
            if (spotNumber != null) 'spot_number': spotNumber,
            if (size != null) 'size': size,
            if (row != null) 'row': row,
            if (col != null) 'col': col,
          }));

  @override
  Future<Either<Failure, void>> deleteSpot(String lotId, int spotId) => _call(() => remoteDataSource.deleteSpot(lotId, spotId));

  @override
  Future<Either<Failure, CrossLotRevenueReport>> getRevenueReport(DateTime startDate, DateTime endDate) =>
      _call(() => remoteDataSource.getRevenueReport(startDate, endDate));

  @override
  Future<Either<Failure, CrossLotOccupancyReport>> getOccupancyReport() => _call(() => remoteDataSource.getOccupancyReport());

  @override
  Future<Either<Failure, List<EmployeeDetail>>> getEmployees({String? lotId}) => _call(() => remoteDataSource.getEmployees(lotId: lotId));

  @override
  Future<Either<Failure, EmployeeDetail>> createEmployee({
    required String name,
    required String email,
    required String password,
    String role = 'employee',
    String? assignedLotId,
  }) =>
      _call(() => remoteDataSource.createEmployee({
            'name': name,
            'email': email,
            'password': password,
            'role': role,
            if (assignedLotId != null) 'assigned_lot_id': assignedLotId,
          }));

  @override
  Future<Either<Failure, EmployeeDetail>> updateEmployee(int id, {String? name, String? email, String? role, String? assignedLotId, bool? isActive}) =>
      _call(() => remoteDataSource.updateEmployee(id, {
            if (name != null) 'name': name,
            if (email != null) 'email': email,
            if (role != null) 'role': role,
            if (assignedLotId != null) 'assigned_lot_id': assignedLotId,
            if (isActive != null) 'is_active': isActive,
          }));

  @override
  Future<Either<Failure, void>> deactivateEmployee(int id) => _call(() => remoteDataSource.deactivateEmployee(id));

  @override
  Future<Either<Failure, List<CameraOverviewItem>>> getCameras() => _call(() => remoteDataSource.getCameras());

  @override
  Future<Either<Failure, CameraOverviewItem>> preRegisterCamera({required String cameraUid, required String pairingCode}) =>
      _call(() => remoteDataSource.preRegisterCamera({'camera_uid': cameraUid, 'pairing_code': pairingCode}));

  @override
  Future<Either<Failure, PaginatedAuditLog>> getAuditLog({int page = 1, int pageSize = 50, String? action, String? entityType}) =>
      _call(() => remoteDataSource.getAuditLog(page: page, pageSize: pageSize, action: action, entityType: entityType));
}
