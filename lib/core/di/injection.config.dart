// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a manually created equivalent of injectable_generator output.
// Run `dart run build_runner build` to regenerate when build_runner is available.

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/di/register_module.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/network/sync_service.dart';
import 'package:parkflow_manager/core/services/incident_service.dart';

// Auth
import 'package:parkflow_manager/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:parkflow_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:parkflow_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parkflow_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:parkflow_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:parkflow_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';

// Parking Session
import 'package:parkflow_manager/features/parking_session/data/datasources/session_local_datasource.dart';
import 'package:parkflow_manager/features/parking_session/data/datasources/session_remote_datasource.dart';
import 'package:parkflow_manager/features/parking_session/data/repositories/parking_session_repository_impl.dart';
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart';
import 'package:parkflow_manager/features/parking_session/domain/usecases/get_active_sessions.dart';
import 'package:parkflow_manager/features/parking_session/domain/usecases/create_session.dart';
import 'package:parkflow_manager/features/parking_session/presentation/bloc/session_cubit.dart';

// Lot Map
import 'package:parkflow_manager/features/lot_map/data/datasources/lot_local_datasource.dart';
import 'package:parkflow_manager/features/lot_map/data/datasources/lot_remote_datasource.dart';
import 'package:parkflow_manager/features/lot_map/data/repositories/lot_repository_impl.dart';
import 'package:parkflow_manager/features/lot_map/domain/repositories/lot_repository.dart';
import 'package:parkflow_manager/features/lot_map/domain/usecases/get_lot_spots.dart';
import 'package:parkflow_manager/features/lot_map/presentation/bloc/lot_map_cubit.dart';

// Payment
import 'package:parkflow_manager/features/payment/data/datasources/payment_local_datasource.dart';
import 'package:parkflow_manager/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:parkflow_manager/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:parkflow_manager/features/payment/domain/repositories/payment_repository.dart';
import 'package:parkflow_manager/features/payment/domain/usecases/calculate_fee.dart';
import 'package:parkflow_manager/features/payment/presentation/bloc/checkout_bloc.dart';

// Reports
import 'package:parkflow_manager/features/reports/data/datasources/report_local_datasource.dart';
import 'package:parkflow_manager/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:parkflow_manager/features/reports/data/repositories/report_repository_impl.dart';
import 'package:parkflow_manager/features/reports/domain/repositories/report_repository.dart';
import 'package:parkflow_manager/features/reports/presentation/bloc/reports_cubit.dart';

// Employee Management
import 'package:parkflow_manager/features/employee_management/data/datasources/employee_local_datasource.dart';
import 'package:parkflow_manager/features/employee_management/data/datasources/employee_remote_datasource.dart';
import 'package:parkflow_manager/features/employee_management/data/repositories/employee_repository_impl.dart';
import 'package:parkflow_manager/features/employee_management/domain/repositories/employee_repository.dart';
import 'package:parkflow_manager/features/employee_management/presentation/bloc/employee_cubit.dart';

extension GetItInjectableX on GetIt {
  // ignore: long-method
  Future<GetIt> init({
    String? environment,
    EnvironmentFilter? environmentFilter,
  }) async {
    final gh = GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();

    // ──────────── Core Singletons (order matters) ────────────

    // 1. FlutterSecureStorage — no dependencies
    gh.singleton<FlutterSecureStorage>(registerModule.secureStorage);

    // 2. Connectivity — no dependencies
    gh.singleton<Connectivity>(registerModule.connectivity);

    // 3. NetworkInfo — depends on Connectivity
    gh.singleton<NetworkInfo>(
      registerModule.networkInfo(get<Connectivity>()),
    );

    // 4. ApiClient — depends on FlutterSecureStorage
    gh.singleton<ApiClient>(
      registerModule.apiClient(get<FlutterSecureStorage>()),
    );

    // 5. AppDatabase — async preResolve
    final database = await registerModule.database();
    gh.singleton<AppDatabase>(database);

    // 6. SyncService — depends on AppDatabase, ApiClient, NetworkInfo
    gh.singleton<SyncService>(
      registerModule.syncService(
        get<AppDatabase>(),
        get<ApiClient>(),
        get<NetworkInfo>(),
      ),
    );

    // 7. IncidentService — depends on AppDatabase
    gh.singleton<IncidentService>(
      registerModule.incidentService(get<AppDatabase>()),
    );

    // ──────────── Auth Feature ────────────

    gh.factory<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        secureStorage: get<FlutterSecureStorage>(),
      ),
    );

    gh.factory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(apiClient: get<ApiClient>()),
    );

    gh.factory<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: get<AuthRemoteDataSource>(),
        localDataSource: get<AuthLocalDataSource>(),
        networkInfo: get<NetworkInfo>(),
      ),
    );

    gh.factory<LoginUseCase>(
      () => LoginUseCase(repository: get<AuthRepository>()),
    );

    gh.factory<LogoutUseCase>(
      () => LogoutUseCase(repository: get<AuthRepository>()),
    );

    gh.factory<AuthBloc>(
      () => AuthBloc(
        loginUseCase: get<LoginUseCase>(),
        logoutUseCase: get<LogoutUseCase>(),
        authRepository: get<AuthRepository>(),
      ),
    );

    // ──────────── Parking Session Feature ────────────

    gh.factory<SessionLocalDataSource>(
      () => SessionLocalDataSourceImpl(database: get<AppDatabase>()),
    );

    gh.factory<SessionRemoteDataSource>(
      () => SessionRemoteDataSourceImpl(apiClient: get<ApiClient>()),
    );

    gh.factory<ParkingSessionRepository>(
      () => ParkingSessionRepositoryImpl(
        localDataSource: get<SessionLocalDataSource>(),
        remoteDataSource: get<SessionRemoteDataSource>(),
        networkInfo: get<NetworkInfo>(),
        database: get<AppDatabase>(),
      ),
    );

    gh.factory<GetActiveSessions>(
      () => GetActiveSessions(
        repository: get<ParkingSessionRepository>(),
      ),
    );

    gh.factory<CreateSession>(
      () => CreateSession(
        repository: get<ParkingSessionRepository>(),
      ),
    );

    gh.factory<SessionCubit>(
      () => SessionCubit(
        getActiveSessions: get<GetActiveSessions>(),
        repository: get<ParkingSessionRepository>(),
      ),
    );

    // ──────────── Lot Map Feature ────────────

    gh.factory<LotLocalDataSource>(
      () => LotLocalDataSourceImpl(database: get<AppDatabase>()),
    );

    gh.factory<LotRemoteDataSource>(
      () => LotRemoteDataSourceImpl(apiClient: get<ApiClient>()),
    );

    gh.factory<LotRepository>(
      () => LotRepositoryImpl(
        localDataSource: get<LotLocalDataSource>(),
        remoteDataSource: get<LotRemoteDataSource>(),
        networkInfo: get<NetworkInfo>(),
      ),
    );

    gh.factory<GetLotSpots>(
      () => GetLotSpots(repository: get<LotRepository>()),
    );

    gh.factory<LotMapCubit>(
      () => LotMapCubit(lotRepository: get<LotRepository>()),
    );

    // ──────────── Payment Feature ────────────

    gh.factory<PaymentLocalDataSource>(
      () => PaymentLocalDataSourceImpl(database: get<AppDatabase>()),
    );

    gh.factory<PaymentRemoteDataSource>(
      () => PaymentRemoteDataSourceImpl(apiClient: get<ApiClient>()),
    );

    gh.factory<PaymentRepository>(
      () => PaymentRepositoryImpl(
        localDataSource: get<PaymentLocalDataSource>(),
        remoteDataSource: get<PaymentRemoteDataSource>(),
        networkInfo: get<NetworkInfo>(),
        database: get<AppDatabase>(),
      ),
    );

    gh.factory<CalculateFee>(() => CalculateFee());

    gh.factory<CheckoutBloc>(
      () => CheckoutBloc(
        sessionRepository: get<ParkingSessionRepository>(),
        paymentRepository: get<PaymentRepository>(),
        calculateFee: get<CalculateFee>(),
      ),
    );

    // ──────────── Reports Feature ────────────

    gh.factory<ReportLocalDataSource>(
      () => ReportLocalDataSourceImpl(database: get<AppDatabase>()),
    );

    gh.factory<ReportRemoteDataSource>(
      () => ReportRemoteDataSourceImpl(apiClient: get<ApiClient>()),
    );

    gh.factory<ReportRepository>(
      () => ReportRepositoryImpl(
        localDataSource: get<ReportLocalDataSource>(),
        database: get<AppDatabase>(),
      ),
    );

    gh.factory<ReportsCubit>(
      () => ReportsCubit(reportRepository: get<ReportRepository>()),
    );

    // ──────────── Employee Management Feature ────────────

    gh.factory<EmployeeLocalDataSource>(
      () => EmployeeLocalDataSourceImpl(database: get<AppDatabase>()),
    );

    gh.factory<EmployeeRemoteDataSource>(
      () => EmployeeRemoteDataSourceImpl(apiClient: get<ApiClient>()),
    );

    gh.factory<EmployeeRepository>(
      () => EmployeeRepositoryImpl(
        localDataSource: get<EmployeeLocalDataSource>(),
        remoteDataSource: get<EmployeeRemoteDataSource>(),
        sessionLocalDataSource: get<SessionLocalDataSource>(),
        networkInfo: get<NetworkInfo>(),
      ),
    );

    gh.factory<EmployeeCubit>(
      () => EmployeeCubit(repository: get<EmployeeRepository>()),
    );

    return this;
  }
}

class _$RegisterModule extends RegisterModule {}
