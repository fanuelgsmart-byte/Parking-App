import 'package:equatable/equatable.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';

typedef LotId = String;
typedef SessionId = int;
typedef EmployeeId = String;

typedef BusinessId = String;

class AppSessionContext extends Equatable {
  const AppSessionContext({
    required this.userId,
    required this.role,
    required this.assignedLotId,
    this.businessId,
    this.operationMode,
    this.selectedLotId,
  });

  final String userId;
  final UserRole role;
  final BusinessId? businessId;
  /// "manual" or "camera_gate"
  final String? operationMode;
  final LotId? assignedLotId;
  final LotId? selectedLotId;

  LotId? get effectiveLotId => selectedLotId ?? assignedLotId;

  bool get hasLotAccess => effectiveLotId != null && effectiveLotId!.isNotEmpty;

  bool get hasBusiness => businessId != null && businessId!.isNotEmpty;

  bool get isCameraMode => operationMode == 'camera_gate';

  bool get isManualMode => operationMode == 'manual' || operationMode == null;

  LotId requireLotId() {
    final lotId = effectiveLotId;
    if (lotId == null || lotId.isEmpty) {
      throw const MissingSessionContextException(
        'No parking lot is assigned to this account.',
      );
    }
    return lotId;
  }

  AppSessionContext copyWith({
    String? userId,
    UserRole? role,
    BusinessId? businessId,
    String? operationMode,
    LotId? assignedLotId,
    LotId? selectedLotId,
    bool clearSelectedLotId = false,
  }) {
    return AppSessionContext(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      businessId: businessId ?? this.businessId,
      operationMode: operationMode ?? this.operationMode,
      assignedLotId: assignedLotId ?? this.assignedLotId,
      selectedLotId:
          clearSelectedLotId ? null : selectedLotId ?? this.selectedLotId,
    );
  }

  @override
  List<Object?> get props =>
      [userId, role, businessId, operationMode, assignedLotId, selectedLotId];
}

class MissingSessionContextException implements Exception {
  const MissingSessionContextException(this.message);

  final String message;

  @override
  String toString() => message;
}
