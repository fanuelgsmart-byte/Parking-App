import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/storage_keys.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/features/auth/data/models/auth_session_model.dart';
import 'package:parkflow_manager/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheSession(AuthSessionModel session);
  Future<AuthSessionModel?> getCachedSession();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> updateTokenBundle(AuthTokenRefreshModel tokenBundle);
  Future<void> clearAll();
}

@Injectable(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({required this.secureStorage});

  final FlutterSecureStorage secureStorage;

  @override
  Future<void> cacheSession(AuthSessionModel session) async {
    try {
      await secureStorage.write(
        key: StorageKeys.cachedUser,
        value: jsonEncode(session.user.toJson()),
      );
      await secureStorage.write(
        key: StorageKeys.accessToken,
        value: session.accessToken,
      );
      await secureStorage.write(
        key: StorageKeys.refreshToken,
        value: session.refreshToken,
      );
      await secureStorage.write(key: StorageKeys.hmacKey, value: session.hmacKey);
      await secureStorage.write(
        key: StorageKeys.accessTokenExpiresAt,
        value: session.accessTokenExpiresAt?.toIso8601String(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache auth session: $e');
    }
  }

  @override
  Future<AuthSessionModel?> getCachedSession() async {
    try {
      final userJson = await secureStorage.read(key: StorageKeys.cachedUser);
      final accessToken = await secureStorage.read(key: StorageKeys.accessToken);
      final refreshToken = await secureStorage.read(key: StorageKeys.refreshToken);
      final hmacKey = await secureStorage.read(key: StorageKeys.hmacKey);
      final expiry = await secureStorage.read(key: StorageKeys.accessTokenExpiresAt);

      if (userJson == null ||
          accessToken == null ||
          refreshToken == null ||
          hmacKey == null) {
        return null;
      }

      return AuthSessionModel(
        user: UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
        accessToken: accessToken,
        refreshToken: refreshToken,
        hmacKey: hmacKey,
        accessTokenExpiresAt: expiry == null ? null : DateTime.tryParse(expiry),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to read cached auth session: $e');
    }
  }

  @override
  Future<String?> getAccessToken() {
    return secureStorage.read(key: StorageKeys.accessToken);
  }

  @override
  Future<String?> getRefreshToken() {
    return secureStorage.read(key: StorageKeys.refreshToken);
  }

  @override
  Future<void> updateTokenBundle(AuthTokenRefreshModel tokenBundle) async {
    await secureStorage.write(
      key: StorageKeys.accessToken,
      value: tokenBundle.accessToken,
    );
    await secureStorage.write(
      key: StorageKeys.refreshToken,
      value: tokenBundle.refreshToken,
    );
    await secureStorage.write(
      key: StorageKeys.accessTokenExpiresAt,
      value: tokenBundle.accessTokenExpiresAt?.toIso8601String(),
    );
    if (tokenBundle.hmacKey != null && tokenBundle.hmacKey!.isNotEmpty) {
      await secureStorage.write(
        key: StorageKeys.hmacKey,
        value: tokenBundle.hmacKey,
      );
    }
  }

  @override
  Future<void> clearAll() async {
    await secureStorage.delete(key: StorageKeys.cachedUser);
    await secureStorage.delete(key: StorageKeys.accessToken);
    await secureStorage.delete(key: StorageKeys.refreshToken);
    await secureStorage.delete(key: StorageKeys.hmacKey);
    await secureStorage.delete(key: StorageKeys.accessTokenExpiresAt);
  }
}
