import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/security/login_throttle.dart';
import 'package:parkflow_manager/core/utils/usecase.dart';
import 'package:parkflow_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:parkflow_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:parkflow_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;
  final LoginThrottle _throttle = LoginThrottle(maxAttempts: 3);

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (session) => emit(AuthAuthenticated(session: session)),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_throttle.isLocked) {
      final remaining = _throttle.remainingLockout;
      emit(
        AuthError(
          message:
              'Too many failed attempts. Try again in ${remaining.inSeconds}s.',
        ),
      );
      return;
    }

    emit(const AuthLoading());

    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) {
        final lockDuration = _throttle.recordFailure();
        if (lockDuration > Duration.zero) {
          emit(
            AuthError(
              message:
                  'Login failed. Account locked for ${lockDuration.inSeconds}s.',
            ),
          );
        } else {
          final remaining = _throttle.maxAttempts - _throttle.failedAttempts;
          emit(
            AuthError(
              message: '${failure.message} ($remaining attempts remaining)',
            ),
          );
        }
      },
      (session) {
        _throttle.reset();
        emit(AuthAuthenticated(session: session));
      },
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await logoutUseCase(const NoParams());
    emit(const AuthUnauthenticated());
  }
}
