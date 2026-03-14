import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
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
  final List<ParkingSession> sessions;

  const SessionLoaded({required this.sessions});

  @override
  List<Object?> get props => [sessions];
}

class SessionError extends SessionState {
  final String message;

  const SessionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ──────────────────────────── Cubit ────────────────────────────

class SessionCubit extends Cubit<SessionState> {
  final GetActiveSessions getActiveSessions;

  SessionCubit({required this.getActiveSessions})
      : super(const SessionInitial());

  Future<void> loadActiveSessions(String lotId) async {
    emit(const SessionLoading());
    final result = await getActiveSessions(lotId);
    result.fold(
      (failure) => emit(SessionError(message: failure.message)),
      (sessions) => emit(SessionLoaded(sessions: sessions)),
    );
  }
}
