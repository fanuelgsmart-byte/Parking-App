import 'package:equatable/equatable.dart';
import 'package:parkflow_manager/core/session/app_session_context.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.hmacKey,
    this.accessTokenExpiresAt,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
  final String hmacKey;
  final DateTime? accessTokenExpiresAt;

  bool get isAccessTokenExpired {
    final expiry = accessTokenExpiresAt;
    if (expiry == null) return false;
    return !DateTime.now().isBefore(expiry);
  }

  AppSessionContext get context => AppSessionContext(
        userId: user.id,
        role: user.role,
        assignedLotId: user.assignedLotId,
      );

  @override
  List<Object?> get props => [
        user,
        accessToken,
        refreshToken,
        hmacKey,
        accessTokenExpiresAt,
      ];
}
