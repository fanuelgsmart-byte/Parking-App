import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/services/incident_service.dart';

abstract class IncidentState extends Equatable {
  const IncidentState();

  @override
  List<Object?> get props => [];
}

class IncidentInitial extends IncidentState {
  const IncidentInitial();
}

class IncidentSubmitting extends IncidentState {
  const IncidentSubmitting();
}

class IncidentSuccess extends IncidentState {
  const IncidentSuccess();
}

class IncidentError extends IncidentState {
  const IncidentError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

@injectable
class IncidentCubit extends Cubit<IncidentState> {
  IncidentCubit({required this.incidentService}) : super(const IncidentInitial());

  final IncidentService incidentService;

  Future<bool> logIncident({
    required String lotId,
    required String employeeId,
    required IncidentType type,
    required String description,
    String? licensePlate,
  }) async {
    emit(const IncidentSubmitting());
    try {
      await incidentService.logIncident(
        lotId: lotId,
        employeeId: employeeId,
        type: type,
        description: description,
        licensePlate: licensePlate,
      );
      emit(const IncidentSuccess());
      return true;
    } catch (e) {
      emit(IncidentError(e.toString()));
      return false;
    }
  }
}
