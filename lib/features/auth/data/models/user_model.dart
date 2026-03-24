import 'package:parkflow_manager/features/auth/domain/entities/user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.businessId,
    this.assignedLotId,
    this.operationMode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (value) => value.name == (json['role'] as String),
        orElse: () => UserRole.employee,
      ),
      businessId: json['business_id'] as String?,
      assignedLotId: json['assigned_lot_id'] as String?,
      operationMode: json['operation_mode'] as String?,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      businessId: user.businessId,
      assignedLotId: user.assignedLotId,
      operationMode: user.operationMode,
    );
  }

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? businessId;
  final String? assignedLotId;
  final String? operationMode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'business_id': businessId,
      'assigned_lot_id': assignedLotId,
      'operation_mode': operationMode,
    };
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      businessId: businessId,
      assignedLotId: assignedLotId,
      operationMode: operationMode,
    );
  }
}
