import 'package:parkflow_manager/features/auth/domain/entities/user.dart';

class UserModel {

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.assignedLotId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      assignedLotId: json['assigned_lot_id'] as String?,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      assignedLotId: user.assignedLotId,
    );
  }
  final String id;
  final String name;
  final String email;
  final String role;
  final String? assignedLotId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'assigned_lot_id': assignedLotId,
    };
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      assignedLotId: assignedLotId,
    );
  }
}
