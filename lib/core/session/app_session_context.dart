import 'package:equatable/equatable.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';

typedef LotId = String;
typedef SessionId = int;
typedef EmployeeId = String;

class AppSessionContext extends Equatable {
  const AppSessionContext({
    required this.userId,
    required this.role,
    required this.assignedLotId,
    this.selectedLotId,
  });

  final String userId;
  final UserRole role;
  final LotId? assignedLotId;
  final LotId? selectedLotId;

  LotId? get effectiveLotId => selectedLotId ?? assignedLotId;

  bool get hasLotAccess => effectiveLotId != null && effectiveLotId!.isNotEmpty;

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
    LotId? assignedLotId,
    LotId? selectedLotId,
    bool clearSelectedLotId = false,
  }) {
    return AppSessionContext(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      assignedLotId: assignedLotId ?? this.assignedLotId,
      selectedLotId:
          clearSelectedLotId ? null : selectedLotId ?? this.selectedLotId,
    );
  }

  @override
  List<Object?> get props => [userId, role, assignedLotId, selectedLotId];
}

class MissingSessionContextException implements Exception {
  const MissingSessionContextException(this.message);

  final String message;

  @override
  String toString() => message;
}
