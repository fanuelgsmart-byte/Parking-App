import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthSession>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthSession>> getCurrentUser();
  Future<Either<Failure, bool>> isAuthenticated();
  Future<Either<Failure, void>> refreshToken();
}
