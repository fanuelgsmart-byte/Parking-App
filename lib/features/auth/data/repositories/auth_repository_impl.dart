import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:parkflow_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:parkflow_manager/features/auth/data/models/auth_session_model.dart';
import 'package:parkflow_manager/features/auth/domain/entities/auth_session.dart';
import 'package:parkflow_manager/features/auth/domain/repositories/auth_repository.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, AuthSession>> login(
    String email,
    String password,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'Internet connection required to login.'),
      );
    }

    try {
      final sessionModel = await remoteDataSource.login(email, password);
      await localDataSource.cacheSession(sessionModel);
      return Right(sessionModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }
      await localDataSource.clearAll();
      return const Right(null);
    } on ServerException catch (e) {
      await localDataSource.clearAll();
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> getCurrentUser() async {
    try {
      final cachedSession = await localDataSource.getCachedSession();
      if (cachedSession == null) {
        return const Left(AuthFailure(message: 'No user found. Please login.'));
      }

      if (cachedSession.toEntity().isAccessTokenExpired) {
        final refreshed = await refreshToken();
        if (refreshed.isLeft) {
          await localDataSource.clearAll();
          return const Left(
            AuthFailure(message: 'Session expired. Please login again.'),
          );
        }
        final afterRefresh = await localDataSource.getCachedSession();
        if (afterRefresh == null) {
          return const Left(
            AuthFailure(message: 'Session refresh failed. Please login again.'),
          );
        }
        return Right(afterRefresh.toEntity());
      }

      return Right(cachedSession.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final token = await localDataSource.getAccessToken();
      return Right(token != null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> refreshToken() async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'Internet connection required to refresh session.'),
      );
    }

    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return const Left(AuthFailure(message: 'No refresh token available.'));
      }

      final currentSession = await localDataSource.getCachedSession();
      if (currentSession == null) {
        return const Left(AuthFailure(message: 'No cached session to refresh.'));
      }

      final refreshed = await remoteDataSource.refreshToken(refreshToken);
      final mergedBundle = AuthTokenRefreshModel(
        accessToken: refreshed.accessToken,
        refreshToken:
            refreshed.refreshToken.isEmpty ? refreshToken : refreshed.refreshToken,
        hmacKey: refreshed.hmacKey ?? currentSession.hmacKey,
        accessTokenExpiresAt: refreshed.accessTokenExpiresAt,
      );

      await localDataSource.updateTokenBundle(mergedBundle);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
