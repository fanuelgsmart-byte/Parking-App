import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';

/// Base class for all use cases.
/// [Type] is the return type, [Params] is the input parameter type.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use when the use case requires no parameters.
class NoParams {
  const NoParams();
}
