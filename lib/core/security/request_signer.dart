import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Signs critical API requests using HMAC-SHA256.
///
/// Adds the following headers to requests:
/// - `X-Request-Timestamp`: Unix epoch milliseconds
/// - `X-Request-Signature`: HMAC-SHA256 of (timestamp + method + path + body)
///
/// The server validates the timestamp is within a 5-minute window to
/// prevent replay attacks, and verifies the HMAC matches.
class RequestSigner {

  RequestSigner({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;
  final FlutterSecureStorage _secureStorage;

  static const _hmacKeyName = 'parkflow_hmac_key';

  /// Paths that require HMAC signing (critical mutations).
  static const signedPaths = [
    '/sessions',      // create session
    '/payments',      // process payment
    '/payments/qr',   // request QR code
    '/employees',     // add/modify employee
  ];

  /// Returns true if this request path requires signing.
  bool shouldSign(String method, String path) {
    if (method == 'GET') return false; // Only sign mutations
    return signedPaths.any((p) => path.startsWith(p));
  }

  /// Generate signature headers for a request.
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

  /// Retrieve or create the HMAC signing key.
  /// In production, this key is provisioned by the server during login
  /// and stored in secure storage.
  Future<String> _getHmacKey() async {
    final existing = await _secureStorage.read(key: _hmacKeyName);
    if (existing != null) return existing;

    // Fallback: generate a client key (server should provision this)
    const defaultKey = 'parkflow-hmac-default-replace-in-production';
    await _secureStorage.write(key: _hmacKeyName, value: defaultKey);
    return defaultKey;
  }

  /// Store a server-provisioned HMAC key (called after login).
  Future<void> setHmacKey(String key) async {
    await _secureStorage.write(key: _hmacKeyName, value: key);
  }

  /// Clear the HMAC key (called on logout).
  Future<void> clearHmacKey() async {
    await _secureStorage.delete(key: _hmacKeyName);
  }
}
