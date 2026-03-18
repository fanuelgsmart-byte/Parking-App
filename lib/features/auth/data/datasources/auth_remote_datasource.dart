import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/auth/data/models/auth_session_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login(String email, String password);
  Future<AuthTokenRefreshModel> refreshToken(String refreshToken);
  Future<void> logout();
}

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<AuthSessionModel> login(String email, String password) async {
    try {
      final response = await apiClient.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthSessionModel.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<AuthTokenRefreshModel> refreshToken(String refreshToken) async {
    try {
      final response = await apiClient.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      return AuthTokenRefreshModel.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConstants.logout);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
