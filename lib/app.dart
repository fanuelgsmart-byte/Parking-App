import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/di/injection.dart';
import 'package:parkflow_manager/core/network/sync_coordinator.dart';
import 'package:parkflow_manager/core/network/sync_health_cubit.dart';
import 'package:parkflow_manager/core/router/app_router.dart';
import 'package:parkflow_manager/core/services/biometric_service.dart';
import 'package:parkflow_manager/core/services/incident_cubit.dart';
import 'package:parkflow_manager/core/services/session_timeout_service.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:parkflow_manager/features/employee_management/presentation/bloc/employee_cubit.dart';
import 'package:parkflow_manager/features/lot_map/presentation/bloc/lot_map_cubit.dart';
import 'package:parkflow_manager/features/parking_session/presentation/bloc/session_cubit.dart';
import 'package:parkflow_manager/features/reports/presentation/bloc/reports_cubit.dart';

class ParkFlowApp extends StatefulWidget {
  const ParkFlowApp({super.key});

  @override
  State<ParkFlowApp> createState() => _ParkFlowAppState();
}

class _ParkFlowAppState extends State<ParkFlowApp> with WidgetsBindingObserver {
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;
  late final SessionTimeoutService _timeoutService;
  late final SyncCoordinator _syncCoordinator;
  final BiometricService _biometricService = BiometricService();
  DateTime? _pausedAt;
  static const _biometricLockDelay = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
    _appRouter = AppRouter(authBloc: _authBloc, serviceLocator: getIt);
    _syncCoordinator = getIt<SyncCoordinator>()..start();

    _timeoutService = SessionTimeoutService(
      timeout: const Duration(minutes: 15),
      onTimeout: () {
        _authBloc.add(const AuthLogoutRequested());
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeoutService.stop();
    unawaited(_syncCoordinator.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pausedAt = DateTime.now();
      case AppLifecycleState.resumed:
        _onAppResumed();
        _syncCoordinator.triggerSync();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _onAppResumed() async {
    if (_authBloc.state is! AuthAuthenticated) return;
    if (_pausedAt == null) return;

    final elapsed = DateTime.now().difference(_pausedAt!);
    if (elapsed < _biometricLockDelay) return;

    final isAvailable = await _biometricService.isAvailable;
    if (!isAvailable) return;

    final authenticated = await _biometricService.authenticate(
      reason: 'Verify your identity to continue',
    );

    if (!authenticated) {
      _authBloc.add(const AuthLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(create: (_) => getIt<SessionCubit>()),
        BlocProvider(create: (_) => getIt<LotMapCubit>()),
        BlocProvider(create: (_) => getIt<ReportsCubit>()),
        BlocProvider(create: (_) => getIt<EmployeeCubit>()),
        BlocProvider(create: (_) => getIt<IncidentCubit>()),
        BlocProvider(create: (_) => getIt<SyncHealthCubit>()..load()),
      ],
      child: SessionTimeoutListener(
        timeoutService: _timeoutService,
        child: MaterialApp.router(
          title: 'ParkFlow Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
