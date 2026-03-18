import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:parkflow_manager/features/auth/presentation/pages/login_page.dart';
import 'package:parkflow_manager/features/employee_management/presentation/pages/employee_management_page.dart';
import 'package:parkflow_manager/features/lot_map/presentation/pages/lot_map_page.dart';
import 'package:parkflow_manager/features/parking_session/presentation/pages/employee_dashboard_page.dart';
import 'package:parkflow_manager/features/payment/presentation/bloc/checkout_bloc.dart';
import 'package:parkflow_manager/features/payment/presentation/pages/checkout_page.dart';
import 'package:parkflow_manager/features/reports/presentation/bloc/rate_config_cubit.dart';
import 'package:parkflow_manager/features/reports/presentation/pages/manager_dashboard_page.dart';
import 'package:parkflow_manager/features/reports/presentation/pages/rate_config_page.dart';

class AppRouter {
  AppRouter({required this.authBloc, GetIt? serviceLocator})
      : _serviceLocator = serviceLocator ?? GetIt.instance;

  final AuthBloc authBloc;
  final GetIt _serviceLocator;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/employee',
        name: 'employee-dashboard',
        builder: (context, state) => const EmployeeDashboardPage(),
        routes: [
          GoRoute(
            path: 'lot-map',
            name: 'lot-map',
            builder: (context, state) {
              final authState = authBloc.state;
              if (authState is! AuthAuthenticated ||
                  !authState.context.hasLotAccess) {
                return const _MissingLotScopePage();
              }
              return LotMapPage(lotId: authState.context.requireLotId());
            },
          ),
          GoRoute(
            path: 'checkout/:sessionId',
            name: 'checkout',
            builder: (context, state) {
              final raw = state.pathParameters['sessionId'];
              final sessionId = int.tryParse(raw ?? '');
              if (sessionId == null) {
                return const Scaffold(
                  body: Center(child: Text('Invalid session')),
                );
              }
              return BlocProvider(
                create: (_) => _serviceLocator<CheckoutBloc>(),
                child: CheckoutPage(sessionId: sessionId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/manager',
        name: 'manager-dashboard',
        builder: (context, state) => const ManagerDashboardPage(),
        routes: [
          GoRoute(
            path: 'employees',
            name: 'employee-management',
            builder: (context, state) {
              final authState = authBloc.state;
              if (authState is! AuthAuthenticated ||
                  !authState.context.hasLotAccess) {
                return const _MissingLotScopePage();
              }
              return EmployeeManagementPage(
                lotId: authState.context.requireLotId(),
              );
            },
          ),
          GoRoute(
            path: 'rates',
            name: 'rate-config',
            builder: (context, state) {
              final authState = authBloc.state;
              if (authState is! AuthAuthenticated ||
                  !authState.context.hasLotAccess) {
                return const _MissingLotScopePage();
              }
              final lotId = authState.context.requireLotId();
              return BlocProvider(
                create: (_) => _serviceLocator<RateConfigCubit>()..loadRates(lotId),
                child: RateConfigPage(lotId: lotId),
              );
            },
          ),
        ],
      ),
    ],
  );

  String? _guard(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final location = state.matchedLocation;
    final isOnLogin = location == '/login';

    if (authState is AuthUnauthenticated && !isOnLogin) {
      return '/login';
    }

    if (authState is AuthAuthenticated && isOnLogin) {
      return authState.user.role == UserRole.manager ? '/manager' : '/employee';
    }

    if (authState is AuthAuthenticated) {
      final role = authState.user.role;
      if (role == UserRole.employee && location.startsWith('/manager')) {
        return '/employee';
      }
      if (role == UserRole.manager && location.startsWith('/employee')) {
        return null;
      }
    }

    return null;
  }
}

class _MissingLotScopePage extends StatelessWidget {
  const _MissingLotScopePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This account has no assigned parking lot. Please contact a manager.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
