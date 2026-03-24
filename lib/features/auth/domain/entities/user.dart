import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    String? businessId,
    String? assignedLotId,
    String? operationMode,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

enum UserRole {
  employee,
  manager;

  bool get isManager => this == UserRole.manager;
  bool get isEmployee => this == UserRole.employee;

  String get label {
    switch (this) {
      case UserRole.employee:
        return 'Employee';
      case UserRole.manager:
        return 'Manager';
    }
  }
}
