// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:parkflow_manager/core/database/app_database.dart' as _i290;
import 'package:parkflow_manager/core/di/register_module.dart' as _i233;
import 'package:parkflow_manager/core/network/api_client.dart' as _i100;
import 'package:parkflow_manager/core/network/network_info.dart' as _i527;
import 'package:parkflow_manager/core/network/sync_coordinator.dart' as _i792;
import 'package:parkflow_manager/core/network/sync_health_cubit.dart' as _i232;
import 'package:parkflow_manager/core/network/sync_service.dart' as _i107;
import 'package:parkflow_manager/core/services/incident_cubit.dart' as _i856;
import 'package:parkflow_manager/core/services/incident_service.dart' as _i1058;
import 'package:parkflow_manager/core/services/outbox_service.dart' as _i922;
import 'package:parkflow_manager/features/auth/data/datasources/auth_local_datasource.dart'
    as _i942;
import 'package:parkflow_manager/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i100;
import 'package:parkflow_manager/features/auth/data/repositories/auth_repository_impl.dart'
    as _i880;
import 'package:parkflow_manager/features/auth/domain/repositories/auth_repository.dart'
    as _i516;
import 'package:parkflow_manager/features/auth/domain/usecases/login_usecase.dart'
    as _i463;
import 'package:parkflow_manager/features/auth/domain/usecases/logout_usecase.dart'
    as _i732;
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart'
    as _i607;
import 'package:parkflow_manager/features/employee_management/data/datasources/employee_local_datasource.dart'
    as _i835;
import 'package:parkflow_manager/features/employee_management/data/datasources/employee_remote_datasource.dart'
    as _i442;
import 'package:parkflow_manager/features/employee_management/data/repositories/employee_repository_impl.dart'
    as _i959;
import 'package:parkflow_manager/features/employee_management/domain/repositories/employee_repository.dart'
    as _i122;
import 'package:parkflow_manager/features/employee_management/presentation/bloc/employee_cubit.dart'
    as _i259;
import 'package:parkflow_manager/features/lot_map/data/datasources/lot_local_datasource.dart'
    as _i72;
import 'package:parkflow_manager/features/lot_map/data/datasources/lot_remote_datasource.dart'
    as _i942;
import 'package:parkflow_manager/features/lot_map/data/repositories/lot_repository_impl.dart'
    as _i628;
import 'package:parkflow_manager/features/lot_map/domain/repositories/lot_repository.dart'
    as _i921;
import 'package:parkflow_manager/features/lot_map/domain/usecases/get_lot_spots.dart'
    as _i439;
import 'package:parkflow_manager/features/lot_map/presentation/bloc/lot_map_cubit.dart'
    as _i942;
import 'package:parkflow_manager/features/parking_session/data/datasources/session_local_datasource.dart'
    as _i560;
import 'package:parkflow_manager/features/parking_session/data/datasources/session_remote_datasource.dart'
    as _i894;
import 'package:parkflow_manager/features/parking_session/data/repositories/parking_session_repository_impl.dart'
    as _i322;
import 'package:parkflow_manager/features/parking_session/domain/repositories/parking_session_repository.dart'
    as _i443;
import 'package:parkflow_manager/features/parking_session/domain/usecases/create_session.dart'
    as _i579;
import 'package:parkflow_manager/features/parking_session/domain/usecases/get_active_sessions.dart'
    as _i651;
import 'package:parkflow_manager/features/parking_session/presentation/bloc/session_cubit.dart'
    as _i65;
import 'package:parkflow_manager/features/payment/data/datasources/payment_local_datasource.dart'
    as _i982;
import 'package:parkflow_manager/features/payment/data/datasources/payment_remote_datasource.dart'
    as _i299;
import 'package:parkflow_manager/features/payment/data/repositories/payment_repository_impl.dart'
    as _i563;
import 'package:parkflow_manager/features/payment/domain/repositories/payment_repository.dart'
    as _i765;
import 'package:parkflow_manager/features/payment/domain/usecases/calculate_fee.dart'
    as _i971;
import 'package:parkflow_manager/features/payment/presentation/bloc/checkout_bloc.dart'
    as _i328;
import 'package:parkflow_manager/features/reports/data/datasources/rate_local_datasource.dart'
    as _i476;
import 'package:parkflow_manager/features/reports/data/datasources/report_local_datasource.dart'
    as _i619;
import 'package:parkflow_manager/features/reports/data/datasources/report_remote_datasource.dart'
    as _i491;
import 'package:parkflow_manager/features/reports/data/repositories/rate_repository_impl.dart'
    as _i763;
import 'package:parkflow_manager/features/reports/data/repositories/report_repository_impl.dart'
    as _i300;
import 'package:parkflow_manager/features/reports/domain/repositories/rate_repository.dart'
    as _i86;
import 'package:parkflow_manager/features/reports/domain/repositories/report_repository.dart'
    as _i973;
import 'package:parkflow_manager/features/reports/domain/usecases/get_effective_rate.dart'
    as _i351;
import 'package:parkflow_manager/features/reports/presentation/bloc/rate_config_cubit.dart'
    as _i62;
import 'package:parkflow_manager/features/reports/presentation/bloc/reports_cubit.dart'
    as _i705;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.factory<_i971.CalculateFee>(() => _i971.CalculateFee());
    gh.singleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.singleton<_i895.Connectivity>(() => registerModule.connectivity);
    await gh.singletonAsync<_i290.AppDatabase>(
      () => registerModule.database(),
      preResolve: true,
    );
    gh.singleton<_i527.NetworkInfo>(
      () => registerModule.networkInfo(gh<_i895.Connectivity>()),
    );
    gh.factory<_i619.ReportLocalDataSource>(
      () => _i619.ReportLocalDataSourceImpl(database: gh<_i290.AppDatabase>()),
    );
    gh.singleton<_i922.OutboxService>(
      () => _i922.OutboxService(database: gh<_i290.AppDatabase>()),
    );
    gh.singleton<_i1058.IncidentService>(
      () => registerModule.incidentService(gh<_i290.AppDatabase>()),
    );
    gh.factory<_i942.AuthLocalDataSource>(
      () => _i942.AuthLocalDataSourceImpl(
        secureStorage: gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.singleton<_i100.ApiClient>(
      () => registerModule.apiClient(gh<_i558.FlutterSecureStorage>()),
    );
    gh.factory<_i835.EmployeeLocalDataSource>(
      () =>
          _i835.EmployeeLocalDataSourceImpl(database: gh<_i290.AppDatabase>()),
    );
    gh.factory<_i560.SessionLocalDataSource>(
      () => _i560.SessionLocalDataSourceImpl(database: gh<_i290.AppDatabase>()),
    );
    gh.factory<_i72.LotLocalDataSource>(
      () => _i72.LotLocalDataSourceImpl(database: gh<_i290.AppDatabase>()),
    );
    gh.factory<_i476.RateLocalDataSource>(
      () => _i476.RateLocalDataSourceImpl(database: gh<_i290.AppDatabase>()),
    );
    gh.factory<_i982.PaymentLocalDataSource>(
      () => _i982.PaymentLocalDataSourceImpl(database: gh<_i290.AppDatabase>()),
    );
    gh.factory<_i894.SessionRemoteDataSource>(
      () => _i894.SessionRemoteDataSourceImpl(apiClient: gh<_i100.ApiClient>()),
    );
    gh.factory<_i299.PaymentRemoteDataSource>(
      () => _i299.PaymentRemoteDataSourceImpl(apiClient: gh<_i100.ApiClient>()),
    );
    gh.factory<_i442.EmployeeRemoteDataSource>(
      () =>
          _i442.EmployeeRemoteDataSourceImpl(apiClient: gh<_i100.ApiClient>()),
    );
    gh.factory<_i86.RateRepository>(
      () => _i763.RateRepositoryImpl(
        localDataSource: gh<_i476.RateLocalDataSource>(),
        outboxService: gh<_i922.OutboxService>(),
      ),
    );
    gh.singleton<_i107.SyncService>(
      () => registerModule.syncService(
        gh<_i290.AppDatabase>(),
        gh<_i100.ApiClient>(),
        gh<_i527.NetworkInfo>(),
      ),
    );
    gh.factory<_i491.ReportRemoteDataSource>(
      () => _i491.ReportRemoteDataSourceImpl(apiClient: gh<_i100.ApiClient>()),
    );
    gh.factory<_i942.LotRemoteDataSource>(
      () => _i942.LotRemoteDataSourceImpl(apiClient: gh<_i100.ApiClient>()),
    );
    gh.factory<_i856.IncidentCubit>(
      () => _i856.IncidentCubit(incidentService: gh<_i1058.IncidentService>()),
    );
    gh.factory<_i100.AuthRemoteDataSource>(
      () => _i100.AuthRemoteDataSourceImpl(apiClient: gh<_i100.ApiClient>()),
    );
    gh.factory<_i232.SyncHealthCubit>(
      () => _i232.SyncHealthCubit(syncService: gh<_i107.SyncService>()),
    );
    gh.factory<_i765.PaymentRepository>(
      () => _i563.PaymentRepositoryImpl(
        localDataSource: gh<_i982.PaymentLocalDataSource>(),
        remoteDataSource: gh<_i299.PaymentRemoteDataSource>(),
        networkInfo: gh<_i527.NetworkInfo>(),
        database: gh<_i290.AppDatabase>(),
        outboxService: gh<_i922.OutboxService>(),
      ),
    );
    gh.factory<_i516.AuthRepository>(
      () => _i880.AuthRepositoryImpl(
        remoteDataSource: gh<_i100.AuthRemoteDataSource>(),
        localDataSource: gh<_i942.AuthLocalDataSource>(),
        networkInfo: gh<_i527.NetworkInfo>(),
      ),
    );
    gh.factory<_i122.EmployeeRepository>(
      () => _i959.EmployeeRepositoryImpl(
        localDataSource: gh<_i835.EmployeeLocalDataSource>(),
        remoteDataSource: gh<_i442.EmployeeRemoteDataSource>(),
        sessionLocalDataSource: gh<_i560.SessionLocalDataSource>(),
        networkInfo: gh<_i527.NetworkInfo>(),
      ),
    );
    gh.factory<_i443.ParkingSessionRepository>(
      () => _i322.ParkingSessionRepositoryImpl(
        localDataSource: gh<_i560.SessionLocalDataSource>(),
        remoteDataSource: gh<_i894.SessionRemoteDataSource>(),
        networkInfo: gh<_i527.NetworkInfo>(),
        database: gh<_i290.AppDatabase>(),
        outboxService: gh<_i922.OutboxService>(),
      ),
    );
    gh.singleton<_i792.SyncCoordinator>(
      () => _i792.SyncCoordinator(
        networkInfo: gh<_i527.NetworkInfo>(),
        syncService: gh<_i107.SyncService>(),
      ),
    );
    gh.factory<_i351.GetEffectiveRateUseCase>(
      () =>
          _i351.GetEffectiveRateUseCase(repository: gh<_i86.RateRepository>()),
    );
    gh.factory<_i62.RateConfigCubit>(
      () => _i62.RateConfigCubit(repository: gh<_i86.RateRepository>()),
    );
    gh.factory<_i463.LoginUseCase>(
      () => _i463.LoginUseCase(repository: gh<_i516.AuthRepository>()),
    );
    gh.factory<_i732.LogoutUseCase>(
      () => _i732.LogoutUseCase(repository: gh<_i516.AuthRepository>()),
    );
    gh.factory<_i328.CheckoutBloc>(
      () => _i328.CheckoutBloc(
        sessionRepository: gh<_i443.ParkingSessionRepository>(),
        paymentRepository: gh<_i765.PaymentRepository>(),
        getEffectiveRateUseCase: gh<_i351.GetEffectiveRateUseCase>(),
      ),
    );
    gh.factory<_i973.ReportRepository>(
      () => _i300.ReportRepositoryImpl(
        localDataSource: gh<_i619.ReportLocalDataSource>(),
        remoteDataSource: gh<_i491.ReportRemoteDataSource>(),
        networkInfo: gh<_i527.NetworkInfo>(),
      ),
    );
    gh.factory<_i921.LotRepository>(
      () => _i628.LotRepositoryImpl(
        localDataSource: gh<_i72.LotLocalDataSource>(),
        remoteDataSource: gh<_i942.LotRemoteDataSource>(),
        networkInfo: gh<_i527.NetworkInfo>(),
      ),
    );
    gh.factory<_i607.AuthBloc>(
      () => _i607.AuthBloc(
        loginUseCase: gh<_i463.LoginUseCase>(),
        logoutUseCase: gh<_i732.LogoutUseCase>(),
        authRepository: gh<_i516.AuthRepository>(),
      ),
    );
    gh.factory<_i579.CreateSession>(
      () =>
          _i579.CreateSession(repository: gh<_i443.ParkingSessionRepository>()),
    );
    gh.factory<_i651.GetOpenSessions>(
      () => _i651.GetOpenSessions(
        repository: gh<_i443.ParkingSessionRepository>(),
      ),
    );
    gh.factory<_i259.EmployeeCubit>(
      () => _i259.EmployeeCubit(repository: gh<_i122.EmployeeRepository>()),
    );
    gh.factory<_i65.SessionCubit>(
      () => _i65.SessionCubit(
        getOpenSessions: gh<_i651.GetOpenSessions>(),
        repository: gh<_i443.ParkingSessionRepository>(),
      ),
    );
    gh.factory<_i705.ReportsCubit>(
      () => _i705.ReportsCubit(reportRepository: gh<_i973.ReportRepository>()),
    );
    gh.factory<_i439.GetLotSpots>(
      () => _i439.GetLotSpots(repository: gh<_i921.LotRepository>()),
    );
    gh.factory<_i942.LotMapCubit>(
      () => _i942.LotMapCubit(lotRepository: gh<_i921.LotRepository>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i233.RegisterModule {}
