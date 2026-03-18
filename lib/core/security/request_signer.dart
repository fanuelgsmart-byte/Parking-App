import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parkflow_manager/core/constants/storage_keys.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';

class RequestSigner {
  RequestSigner({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  static const signedPaths = [
    '/sessions',
    '/payments',
    '/payments/qr',
    '/employees',
    '/rates',
  ];

  bool shouldSign(String method, String path) {
    if (method == 'GET') return false;
    return signedPaths.any((p) => path.startsWith(p));
  }

  Future<Map<String, String>> sign({
    required String method,
    required String path,
    dynamic body,
  }) async {
    final key = await _getHmacKey();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bodyStr = body != null ? jsonEncode(body) : '';
    final message = '$timestamp:$method:$path:$bodyStr';
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(message));
    return {
      'X-Request-Timestamp': timestamp,
      'X-Request-Signature': digest.toString(),
    };
  }

  Future<String> _getHmacKey() async {
    final existing = await _secureStorage.read(key: StorageKeys.hmacKey);
    if (existing != null && existing.isNotEmpty) return existing;
    if (kDebugMode) {
      const defaultKey = 'parkflow-hmac-debug-only';
      await _secureStorage.write(key: StorageKeys.hmacKey, value: defaultKey);
      return defaultKey;
    }
    throw const AuthException(
      message: 'No HMAC signing key is provisioned for this device.',
    );
  }

  Future<void> setHmacKey(String key) {
    return _secureStorage.write(key: StorageKeys.hmacKey, value: key);
  }

  Future<void> clearHmacKey() {
    return _secureStorage.delete(key: StorageKeys.hmacKey);
  }
}
