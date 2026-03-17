import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/core/utils/usecase.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';
import 'package:parkflow_manager/features/auth/domain/repositories/auth_repository.dart';

@injectable
class LoginUseCase extends UseCase<User, LoginParams> {

  LoginUseCase({required this.repository});
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}

class LoginParams {

  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;
}
