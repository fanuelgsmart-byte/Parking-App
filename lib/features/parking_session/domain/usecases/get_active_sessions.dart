import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/core/utils/usecase.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';

@injectable
class GetActiveSessions extends UseCase<List<ParkingSession>, String> {
  final ParkingSessionRepository repository;

  GetActiveSessions({required this.repository});

  @override
  Future<Either<Failure, List<ParkingSession>>> call(String lotId) {
    return repository.getActiveSessions(lotId);
  }
}
