import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/error/failures.dart';
import 'package:parkflow_manager/core/session/app_session_context.dart';
import 'package:parkflow_manager/core/utils/either.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';
import 'package:parkflow_manager/features/parking_session/domain/usecases/get_active_sessions.dart';

abstract class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {
  const SessionInitial();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionLoaded extends SessionState {
  const SessionLoaded({required this.sessions});

  final List<ParkingSession> sessions;

  @override
  List<Object?> get props => [sessions];
}

class SessionCreated extends SessionState {
  const SessionCreated({required this.session});

  final ParkingSession session;

  @override
  List<Object?> get props => [session];
}

class SessionError extends SessionState {
  const SessionError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class CheckInRequest extends Equatable {
  const CheckInRequest({
    required this.licensePlate,
    required this.vehicleSize,
    required this.vehicleColor,
    required this.lotId,
    required this.employeeId,
  });

  final String licensePlate;
  final VehicleSize vehicleSize;
  final String vehicleColor;
  final LotId lotId;
  final EmployeeId employeeId;

  @override
  List<Object?> get props => [
        licensePlate,
        vehicleSize,
        vehicleColor,
        lotId,
        employeeId,
      ];
}

@injectable
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required this.getOpenSessions,
    required this.repository,
  }) : super(const SessionInitial());

  final GetOpenSessions getOpenSessions;
  final ParkingSessionRepository repository;

  StreamSubscription<List<ParkingSession>>? _watchSub;
  LotId? _currentLotId;

  Future<void> loadOpenSessions(LotId lotId) async {
    _currentLotId = lotId;
    emit(const SessionLoading());
    final result = await getOpenSessions(lotId);
    result.fold(
      (failure) => emit(SessionError(message: failure.message)),
      (sessions) => emit(SessionLoaded(sessions: sessions)),
    );
  }

  void watchSessions(LotId lotId) {
    _currentLotId = lotId;
    _watchSub?.cancel();
    _watchSub = repository.watchOpenSessions(lotId).listen(
      (sessions) => emit(SessionLoaded(sessions: sessions)),
      onError: (Object error) => emit(SessionError(message: error.toString())),
    );
  }

  Future<void> createSession(CheckInRequest request) async {
    emit(const SessionLoading());
    final result = await repository.createSession(
      licensePlate: request.licensePlate,
      vehicleSize: request.vehicleSize,
      vehicleColor: request.vehicleColor,
      lotId: request.lotId,
      employeeId: request.employeeId,
    );

    result.fold(
      (failure) => emit(SessionError(message: failure.message)),
      (session) async {
        emit(SessionCreated(session: session));
        if (_currentLotId != null) {
          await loadOpenSessions(_currentLotId!);
        }
      },
    );
  }

  Future<void> flagForCheckout(SessionId sessionId) async {
    final result = await repository.flagForCheckout(sessionId);
    await _handleMutationResult(result);
  }

  Future<void> markPaymentPending(SessionId sessionId) async {
    final result = await repository.markPaymentPending(sessionId);
    await _handleMutationResult(result);
  }

  Future<void> _handleMutationResult(
    Either<Failure, ParkingSession> result,
  ) async {
    result.fold(
      (failure) => emit(SessionError(message: failure.message)),
      (_) async {
        if (_currentLotId != null) {
          await loadOpenSessions(_currentLotId!);
        }
      },
    );
  }

  @override
  Future<void> close() {
    _watchSub?.cancel();
    return super.close();
  }
}
