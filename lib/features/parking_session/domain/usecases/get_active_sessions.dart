import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/session/app_session_context.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/core/utils/usecase.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';

@injectable
class GetOpenSessions extends UseCase<List<ParkingSession>, LotId> {
  GetOpenSessions({required this.repository});

  final ParkingSessionRepository repository;

  @override
  Future<Either<Failure, List<ParkingSession>>> call(LotId lotId) {
    return repository.getOpenSessions(lotId);
  }
}
