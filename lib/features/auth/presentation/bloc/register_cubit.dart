import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';
import 'package:parkflow_manager/core/error/exceptions.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:parkflow_manager/features/auth/data/models/auth_session_model.dart';
import 'package:parkflow_manager/features/auth/data/models/user_model.dart';
import 'package:parkflow_manager/features/auth/domain/entities/auth_session.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';

// ────────────────── States ──────────────────

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  const RegisterSuccess({required this.session});

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

class RegisterError extends RegisterState {
  const RegisterError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ────────────────── Cubit ──────────────────

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({
    required this.apiClient,
    required this.localDataSource,
  }) : super(const RegisterInitial());

  final ApiClient apiClient;
  final AuthLocalDataSource localDataSource;

  Future<void> register({
    required String businessName,
    required String ownerName,
    required String businessEmail,
    required String phone,
    required String address,
    required String operationMode,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    emit(const RegisterLoading());

    try {
      final response = await apiClient.post(
        ApiConstants.businessRegister,
        data: {
          'business_name': businessName,
          'owner_name': ownerName,
          'business_email': businessEmail,
          'phone': phone.isNotEmpty ? phone : null,
          'address': address.isNotEmpty ? address : null,
          'operation_mode': operationMode,
          'owner_email': ownerEmail,
          'owner_password': ownerPassword,
        },
      );

      final json = response.data as Map<String, dynamic>;

      // Build auth session from registration response
      final userJson = json['business'] as Map<String, dynamic>;
      final userModel = UserModel(
        id: (json['user'] != null)
            ? (json['user'] as Map<String, dynamic>)['id'] as String
            : userJson['id'] as String,
        name: ownerName,
        email: ownerEmail,
        role: _parseRole('manager'),
        businessId: userJson['id'] as String,
        assignedLotId: null,
        operationMode: userJson['operation_mode'] as String?,
      );

      final sessionModel = AuthSessionModel(
        user: userModel,
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        hmacKey: '',
      );

      await localDataSource.cacheSession(sessionModel);
      emit(RegisterSuccess(session: sessionModel.toEntity()));
    } on ServerException catch (e) {
      emit(RegisterError(message: e.message));
    } catch (e) {
      emit(RegisterError(message: e.toString()));
    }
  }

  static UserRole _parseRole(String role) {
    return role == 'manager'
        ? UserRole.manager
        : UserRole.employee;
  }
}
