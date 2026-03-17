import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';
import 'package:parkflow_manager/features/parking_session/domain/usecases/get_active_sessions.dart';

// ──────────────────────────── State ────────────────────────────

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

// ──────────────────────────── Cubit ────────────────────────────

@injectable
class SessionCubit extends Cubit<SessionState> {

  SessionCubit({
    required this.getActiveSessions,
    required this.repository,
  }) : super(const SessionInitial());
  final GetActiveSessions getActiveSessions;
  final ParkingSessionRepository repository;

  StreamSubscription<List<ParkingSession>>? _watchSub;
  String? _currentLotId;

  Future<void> loadActiveSessions(String lotId) async {
    _currentLotId = lotId;
    emit(const SessionLoading());
    final result = await getActiveSessions(lotId);
    result.fold(
      (failure) => emit(SessionError(message: failure.message)),
      (sessions) => emit(SessionLoaded(sessions: sessions)),
    );
  }

  /// Subscribe to real-time spot/session updates via Drift streams.
  void watchSessions(String lotId) {
    _currentLotId = lotId;
    _watchSub?.cancel();
    _watchSub = repository.watchActiveSessions(lotId).listen(
      (sessions) => emit(SessionLoaded(sessions: sessions)),
      onError: (e) => emit(SessionError(message: e.toString())),
    );
  }

  Future<void> createSession({
    required String licensePlate,
    required String vehicleSize,
    required String vehicleColor,
    required int spotId,
    required String lotId,
    required String employeeId,
  }) async {
    emit(const SessionLoading());
    final result = await repository.createSession(
      licensePlate: licensePlate,
      vehicleSize: vehicleSize,
      vehicleColor: vehicleColor,
      spotId: spotId,
      lotId: lotId,
      employeeId: employeeId,
    );

    result.fold(
      (failure) => emit(SessionError(message: failure.message)),
      (session) {
        emit(SessionCreated(session: session));
        // Reload the full list
        if (_currentLotId != null) loadActiveSessions(_currentLotId!);
      },
    );
  }

  Future<void> flagForCheckout(int sessionId) async {
    await repository.flagForCheckout(sessionId);
    if (_currentLotId != null) await loadActiveSessions(_currentLotId!);
  }

  @override
  Future<void> close() {
    _watchSub?.cancel();
    return super.close();
  }
}
