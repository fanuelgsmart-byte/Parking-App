import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  ApiClient({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      _retryInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);
  }

  Dio get dio => _dio;

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
        if (error.response?.statusCode == 401) {
          try {
            await _refreshToken();
            final retryResponse = await _dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
          } on Exception {
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
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) {
      throw const AuthException(message: 'No refresh token available');
    }

    final response = await Dio().post(
      '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
      data: {'refresh_token': refreshToken},
    );

    final newAccessToken = response.data['access_token'] as String;
    final newRefreshToken = response.data['refresh_token'] as String;

    await _secureStorage.write(key: 'access_token', value: newAccessToken);
    await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.post<T>(path, data: data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.put<T>(path, data: data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Response<T>> delete<T>(String path) async {
    try {
      return await _dio.delete<T>(path);
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
