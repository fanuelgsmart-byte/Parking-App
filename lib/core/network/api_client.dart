import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/constants/storage_keys.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/security/request_signer.dart';

class ApiClient {
  ApiClient({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage,
        _requestSigner = RequestSigner(secureStorage: secureStorage) {
    _validateProductionSecurityConfig();

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Content-Type-Options': 'nosniff',
        },
      ),
    );

    _configureCertificatePinning();

    _dio.interceptors.addAll([
      _authInterceptor(),
      _hmacSigningInterceptor(),
      _retryInterceptor(),
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
  final RequestSigner _requestSigner;
  bool _isRefreshing = false;

  Dio get dio => _dio;

  void _validateProductionSecurityConfig() {
    if (kDebugMode) return;
    if (ApiConstants.pinnedHosts.isEmpty ||
        ApiConstants.pinnedFingerprintHex.isEmpty) {
      throw StateError(
        'Release builds require PINNED_HOSTS and PINNED_CERT_SHA256.',
      );
    }
  }

  void _configureCertificatePinning() {
    final httpClientAdapter = _dio.httpClientAdapter;
    if (httpClientAdapter is IOHttpClientAdapter) {
      httpClientAdapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          final validHosts = ApiConstants.pinnedHosts;
          if (!validHosts.contains(host)) {
            return false;
          }
          if (kDebugMode) return true;
          final expectedFingerprint = ApiConstants.pinnedFingerprintHex
              .replaceAll(':', '')
              .toLowerCase();
          final actualFingerprint = sha256
              .convert(cert.der)
              .bytes
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          return actualFingerprint == expectedFingerprint;
        };
        return client;
      };
    }
  }

  InterceptorsWrapper _hmacSigningInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_requestSigner.shouldSign(options.method, options.path)) {
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

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: StorageKeys.accessToken);
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
            final token = await _secureStorage.read(key: StorageKeys.accessToken);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final retryResponse = await _dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
          } on Exception {
            _isRefreshing = false;
            await _secureStorage.delete(key: StorageKeys.accessToken);
            await _secureStorage.delete(key: StorageKeys.refreshToken);
            handler.next(error);
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  InterceptorsWrapper _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error)) {
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

  Future<void> _refreshToken() async {
    final refreshToken =
        await _secureStorage.read(key: StorageKeys.refreshToken);
    if (refreshToken == null) {
      throw const AuthException(message: 'No refresh token available');
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
      ),
    );

    final response = await refreshDio.post(
      ApiConstants.refreshToken,
      data: {'refresh_token': refreshToken},
    );

    final newAccessToken = response.data['access_token'] as String;
    final newRefreshToken = (response.data['refresh_token'] as String?) ?? refreshToken;
    final newHmacKey = response.data['hmac_key'] as String?;
    final rawExpiry = response.data['access_token_expires_at'];
    final rawExpiresIn = response.data['expires_in'];

    await _secureStorage.write(
      key: StorageKeys.accessToken,
      value: newAccessToken,
    );
    await _secureStorage.write(
      key: StorageKeys.refreshToken,
      value: newRefreshToken,
    );
    if (newHmacKey != null && newHmacKey.isNotEmpty) {
      await _secureStorage.write(
        key: StorageKeys.hmacKey,
        value: newHmacKey,
      );
    }
    final expiresAt = rawExpiry is String
        ? DateTime.tryParse(rawExpiry)
        : rawExpiresIn is num
            ? DateTime.now().add(Duration(seconds: rawExpiresIn.toInt()))
            : null;
    await _secureStorage.write(
      key: StorageKeys.accessTokenExpiresAt,
      value: expiresAt?.toIso8601String(),
    );
  }

  static void _sanitizedLog(Object object) {
    var message = object.toString();
    message = message.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'),
      'Bearer ***REDACTED***',
    );
    message = message.replaceAll(
      RegExp(r'"license_plate"\s*:\s*"[^"]*"'),
      '"license_plate": "***MASKED***"',
    );
    message = message.replaceAll(
      RegExp(r'"refresh_token"\s*:\s*"[^"]*"'),
      '"refresh_token": "***REDACTED***"',
    );
    debugPrint(message);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.delete<T>(path, options: Options(headers: headers));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

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

