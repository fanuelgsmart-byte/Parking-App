import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/superadmin/domain/repositories/superadmin_repository.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_state.dart';

@injectable
class SuperadminCubit extends Cubit<SuperadminState> {
  SuperadminCubit({required this.repository}) : super(const SuperadminInitial());
  final SuperadminRepository repository;

  // ── Dashboard ──────────────────────────────────────────────────
  Future<void> loadDashboard() async {
    emit(const SuperadminLoading());
    final result = await repository.getDashboard();
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (stats) => emit(SuperadminDashboardLoaded(stats: stats)),
    );
  }

  // ── Lots ───────────────────────────────────────────────────────
  Future<void> loadLots() async {
    emit(const SuperadminLoading());
    final result = await repository.getLots();
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (lots) => emit(SuperadminLotsLoaded(lots: lots)),
    );
  }

  Future<void> createLot({required String name, String? address, String timezone = 'UTC'}) async {
    emit(const SuperadminLoading());
    final result = await repository.createLot(name: name, address: address, timezone: timezone);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Lot created successfully'));
        await loadLots();
      },
    );
  }

  Future<void> updateLot(String lotId, {String? name, String? address, String? timezone}) async {
    emit(const SuperadminLoading());
    final result = await repository.updateLot(lotId, name: name, address: address, timezone: timezone);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Lot updated successfully'));
        await loadLots();
      },
    );
  }

  Future<void> deleteLot(String lotId) async {
    emit(const SuperadminLoading());
    final result = await repository.deleteLot(lotId);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Lot deleted successfully'));
        await loadLots();
      },
    );
  }

  // ── Spots ──────────────────────────────────────────────────────
  String? _currentLotId;

  Future<void> loadSpots(String lotId) async {
    _currentLotId = lotId;
    emit(const SuperadminLoading());
    final result = await repository.getSpots(lotId);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (spots) => emit(SuperadminSpotsLoaded(spots: spots, lotId: lotId)),
    );
  }

  Future<void> createSpot(String lotId, {required String spotNumber, required String size, int? row, int? col}) async {
    emit(const SuperadminLoading());
    final result = await repository.createSpot(lotId, spotNumber: spotNumber, size: size, row: row, col: col);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Spot created successfully'));
        await loadSpots(lotId);
      },
    );
  }

  Future<void> updateSpot(String lotId, int spotId, {String? spotNumber, String? size, int? row, int? col}) async {
    emit(const SuperadminLoading());
    final result = await repository.updateSpot(lotId, spotId, spotNumber: spotNumber, size: size, row: row, col: col);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Spot updated successfully'));
        await loadSpots(lotId);
      },
    );
  }

  Future<void> deleteSpot(String lotId, int spotId) async {
    emit(const SuperadminLoading());
    final result = await repository.deleteSpot(lotId, spotId);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Spot deleted successfully'));
        if (_currentLotId != null) await loadSpots(_currentLotId!);
      },
    );
  }

  // ── Reports ────────────────────────────────────────────────────
  Future<void> loadRevenueReport(DateTime startDate, DateTime endDate) async {
    emit(const SuperadminLoading());
    final result = await repository.getRevenueReport(startDate, endDate);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (report) => emit(SuperadminRevenueLoaded(report: report)),
    );
  }

  Future<void> loadOccupancyReport() async {
    emit(const SuperadminLoading());
    final result = await repository.getOccupancyReport();
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (report) => emit(SuperadminOccupancyLoaded(report: report)),
    );
  }

  // ── Employees ──────────────────────────────────────────────────
  Future<void> loadEmployees({String? lotId}) async {
    emit(const SuperadminLoading());
    final employeesResult = await repository.getEmployees(lotId: lotId);
    final lotsResult = await repository.getLots();
    employeesResult.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (employees) {
        final lots = lotsResult.fold((_) => <dynamic>[], (l) => l);
        emit(SuperadminEmployeesLoaded(employees: employees, lots: lots.cast()));
      },
    );
  }

  Future<void> createEmployee({
    required String name,
    required String email,
    required String password,
    String role = 'employee',
    String? assignedLotId,
  }) async {
    emit(const SuperadminLoading());
    final result = await repository.createEmployee(
      name: name, email: email, password: password, role: role, assignedLotId: assignedLotId,
    );
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Employee created successfully'));
        await loadEmployees();
      },
    );
  }

  Future<void> updateEmployee(int id, {String? name, String? email, String? role, String? assignedLotId, bool? isActive}) async {
    emit(const SuperadminLoading());
    final result = await repository.updateEmployee(id, name: name, email: email, role: role, assignedLotId: assignedLotId, isActive: isActive);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Employee updated successfully'));
        await loadEmployees();
      },
    );
  }

  Future<void> deactivateEmployee(int id) async {
    emit(const SuperadminLoading());
    final result = await repository.deactivateEmployee(id);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Employee deactivated'));
        await loadEmployees();
      },
    );
  }

  // ── Cameras ────────────────────────────────────────────────────
  Future<void> loadCameras() async {
    emit(const SuperadminLoading());
    final result = await repository.getCameras();
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (cameras) => emit(SuperadminCamerasLoaded(cameras: cameras)),
    );
  }

  Future<void> preRegisterCamera({required String cameraUid, required String pairingCode}) async {
    emit(const SuperadminLoading());
    final result = await repository.preRegisterCamera(cameraUid: cameraUid, pairingCode: pairingCode);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (_) async {
        emit(const SuperadminActionSuccess(message: 'Camera pre-registered'));
        await loadCameras();
      },
    );
  }

  // ── Audit Log ──────────────────────────────────────────────────
  Future<void> loadAuditLog({int page = 1, String? action, String? entityType}) async {
    emit(const SuperadminLoading());
    final result = await repository.getAuditLog(page: page, action: action, entityType: entityType);
    result.fold(
      (f) => emit(SuperadminError(message: f.message)),
      (log) => emit(SuperadminAuditLogLoaded(auditLog: log)),
    );
  }
}
