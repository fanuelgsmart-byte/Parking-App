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
    String? assignedLotId,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

enum UserRole {
  employee,
  manager,
  superadmin;

  bool get isManager => this == UserRole.manager;
  bool get isEmployee => this == UserRole.employee;
  bool get isSuperadmin => this == UserRole.superadmin;

  String get label {
    switch (this) {
      case UserRole.employee:
        return 'Employee';
      case UserRole.manager:
        return 'Manager';
      case UserRole.superadmin:
        return 'Super Admin';
    }
  }
}
