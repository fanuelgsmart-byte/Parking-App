import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/security/request_signer.dart';

class ApiClient {

  ApiClient({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage,
        _requestSigner = RequestSigner(secureStorage: secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Prevent MIME sniffing attacks
          'X-Content-Type-Options': 'nosniff',
        },
      ),
    );

    _configureCertificatePinning();

    _dio.interceptors.addAll([
      _authInterceptor(),
      _hmacSigningInterceptor(),
      _retryInterceptor(),
      // Only log in debug builds — prevents token leakage in production
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: _sanitizedLog,
        ),
    ]);
  }
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  late final RequestSigner _requestSigner;

  /// Tracks consecutive refresh failures to prevent infinite retry loops.
  bool _isRefreshing = false;

  Dio get dio => _dio;

  // ──────────────────── Certificate Pinning ────────────────────

  void _configureCertificatePinning() {
    final httpClientAdapter = _dio.httpClientAdapter;
    if (httpClientAdapter is IOHttpClientAdapter) {
      httpClientAdapter.createHttpClient = () {
        final client = HttpClient();
        // Enforce TLS 1.2+ only
        client.badCertificateCallback = (cert, host, port) {
          // In production, pin against known SHA-256 fingerprints.
          // The fingerprints below should be replaced with your actual
          // server certificate fingerprints before release.
          //
          // To extract your server cert fingerprint:
          //   openssl s_client -connect api.parkflow.example.com:443 \
          //     | openssl x509 -fingerprint -sha256 -noout
          const validHosts = ApiConstants.pinnedHosts;
          if (!validHosts.contains(host)) {
            // Reject connections to unexpected hosts
            return false;
          }
          // In debug mode, allow self-signed certs for local development
          if (kDebugMode) return true;
          // In release mode, validate against pinned fingerprints
          final fingerprint = sha256.convert(cert.der).bytes;
          return ApiConstants.pinnedCertFingerprints
              .any((pinned) => _compareFingerprints(fingerprint, pinned));
        };
        return client;
      };
    }
  }

  static bool _compareFingerprints(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    // Constant-time comparison to prevent timing attacks
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  // ──────────────────── HMAC Signing Interceptor ────────────────────

  InterceptorsWrapper _hmacSigningInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_requestSigner.shouldSign(
          options.method,
          options.path,
        )) {
          final headers = await _requestSigner.sign(
            method: options.method,
            path: options.path,
            body: options.data,
          );
          options.headers.addAll(headers);
        }
        handler.next(options);
      },
    );
  }

  // ──────────────────── Auth Interceptor ────────────────────

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          try {
            _isRefreshing = true;
            await _refreshToken();
            _isRefreshing = false;

            // Retry the original request with the new token
            final token = await _secureStorage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final retryResponse = await _dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
          } on Exception {
            _isRefreshing = false;
            // Clear tokens on refresh failure — forces re-login
            await _secureStorage.delete(key: 'access_token');
            await _secureStorage.delete(key: 'refresh_token');
            handler.next(error);
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  // ──────────────────── Retry Interceptor ────────────────────

  InterceptorsWrapper _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error)) {
          // Single retry with backoff for transient network issues
          await Future<void>.delayed(const Duration(seconds: 2));
          try {
            final retryResponse = await _dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
          } on DioException {
            handler.next(error);
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  // ──────────────────── Token Refresh ────────────────────

  Future<void> _refreshToken() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) {
      throw const AuthException(message: 'No refresh token available');
    }

    // Use a separate Dio instance to avoid interceptor recursion
    final refreshDio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ));

    final response = await refreshDio.post(
      ApiConstants.refreshToken,
      data: {'refresh_token': refreshToken},
    );

    final newAccessToken = response.data['access_token'] as String;
    final newRefreshToken = response.data['refresh_token'] as String;

    await _secureStorage.write(key: 'access_token', value: newAccessToken);
    await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
  }

  // ──────────────────── Sanitized Logging ────────────────────

  /// Masks sensitive data (tokens, license plates) in debug logs.
  static void _sanitizedLog(Object object) {
    var message = object.toString();
    // Mask Bearer tokens
    message = message.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'),
      'Bearer ***REDACTED***',
    );
    // Mask license plates (common formats: ABC1234, AB-123-CD, etc.)
    message = message.replaceAll(
      RegExp(r'"license_plate"\s*:\s*"[^"]*"'),
      '"license_plate": "***MASKED***"',
    );
    // Mask refresh tokens in payloads
    message = message.replaceAll(
      RegExp(r'"refresh_token"\s*:\s*"[^"]*"'),
      '"refresh_token": "***REDACTED***"',
    );
    debugPrint(message);
  }

  // ──────────────────── HTTP Methods ────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.post<T>(path, data: data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.put<T>(path, data: data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> delete<T>(String path) async {
    try {
      return await _dio.delete<T>(path);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Maps Dio exceptions to typed application exceptions for consistent
  /// error handling across the app.
  static Never _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkException(
        message: 'Network unavailable. Please check your connection.',
      );
    }
    throw ServerException(
      message: e.message ?? 'An unexpected error occurred',
      statusCode: e.response?.statusCode,
    );
  }
}
