import 'package:parkflow_manager/features/auth/data/models/user_model.dart';
import 'package:parkflow_manager/features/auth/domain/entities/auth_session.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.hmacKey,
    this.accessTokenExpiresAt,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      hmacKey: json['hmac_key'] as String,
      accessTokenExpiresAt: _parseExpiry(
        rawExpiresAt: json['access_token_expires_at'],
        rawExpiresIn: json['expires_in'],
      ),
    );
  }

  factory AuthSessionModel.fromEntity(AuthSession session) {
    return AuthSessionModel(
      user: UserModel.fromEntity(session.user),
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      hmacKey: session.hmacKey,
      accessTokenExpiresAt: session.accessTokenExpiresAt,
    );
  }

  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String hmacKey;
  final DateTime? accessTokenExpiresAt;

  AuthSessionModel copyWith({
    UserModel? user,
    String? accessToken,
    String? refreshToken,
    String? hmacKey,
    DateTime? accessTokenExpiresAt,
    bool clearAccessTokenExpiry = false,
  }) {
    return AuthSessionModel(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      hmacKey: hmacKey ?? this.hmacKey,
      accessTokenExpiresAt: clearAccessTokenExpiry
          ? null
          : accessTokenExpiresAt ?? this.accessTokenExpiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'hmac_key': hmacKey,
      'access_token_expires_at': accessTokenExpiresAt?.toIso8601String(),
    };
  }

  AuthSession toEntity() {
    return AuthSession(
      user: user.toEntity(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      hmacKey: hmacKey,
      accessTokenExpiresAt: accessTokenExpiresAt,
    );
  }

  static DateTime? _parseExpiry({
    required dynamic rawExpiresAt,
    required dynamic rawExpiresIn,
  }) {
    if (rawExpiresAt is String && rawExpiresAt.isNotEmpty) {
      return DateTime.tryParse(rawExpiresAt);
    }
    if (rawExpiresIn is int) {
      return DateTime.now().add(Duration(seconds: rawExpiresIn));
    }
    if (rawExpiresIn is num) {
      return DateTime.now().add(Duration(seconds: rawExpiresIn.toInt()));
    }
    return null;
  }
}

class AuthTokenRefreshModel {
  const AuthTokenRefreshModel({
    required this.accessToken,
    required this.refreshToken,
    this.hmacKey,
    this.accessTokenExpiresAt,
  });

  factory AuthTokenRefreshModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenRefreshModel(
      accessToken: json['access_token'] as String,
      refreshToken: (json['refresh_token'] as String?) ??
          (json['access_token'] as String),
      hmacKey: json['hmac_key'] as String?,
      accessTokenExpiresAt: AuthSessionModel._parseExpiry(
        rawExpiresAt: json['access_token_expires_at'],
        rawExpiresIn: json['expires_in'],
      ),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String? hmacKey;
  final DateTime? accessTokenExpiresAt;
}
