import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';

/// Base class for all use cases.
/// [Type] is the return type, [Params] is the input parameter type.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use when the use case requires no parameters.
class NoParams {
  const NoParams();
}
