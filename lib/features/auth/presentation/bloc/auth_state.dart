import 'package:equatable/equatable.dart';
import 'package:parkflow_manager/core/session/app_session_context.dart';
import 'package:parkflow_manager/features/auth/domain/entities/auth_session.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.session});

  final AuthSession session;

  User get user => session.user;
  AppSessionContext get context => session.context;

  @override
  List<Object?> get props => [session];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
