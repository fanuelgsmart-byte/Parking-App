import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:parkflow_manager/features/auth/presentation/pages/login_page.dart';
import 'package:parkflow_manager/features/parking_session/presentation/pages/employee_dashboard_page.dart';
import 'package:parkflow_manager/features/reports/presentation/pages/manager_dashboard_page.dart';
import 'package:parkflow_manager/features/lot_map/presentation/pages/lot_map_page.dart';
import 'package:parkflow_manager/features/payment/presentation/pages/checkout_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      // Employee Routes
      GoRoute(
        path: '/employee',
        name: 'employee-dashboard',
        builder: (context, state) => const EmployeeDashboardPage(),
        routes: [
          GoRoute(
            path: 'lot-map',
            name: 'lot-map',
            builder: (context, state) => const LotMapPage(),
          ),
          GoRoute(
            path: 'checkout/:sessionId',
            name: 'checkout',
            builder: (context, state) {
              final sessionId =
                  int.parse(state.pathParameters['sessionId']!);
              return CheckoutPage(sessionId: sessionId);
            },
          ),
        ],
      ),
      // Manager Routes
      GoRoute(
        path: '/manager',
        name: 'manager-dashboard',
        builder: (context, state) => const ManagerDashboardPage(),
      ),
    ],
  );

  String? _guard(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final isOnLogin = state.matchedLocation == '/login';

    if (authState is AuthUnauthenticated && !isOnLogin) {
      return '/login';
    }

    if (authState is AuthAuthenticated && isOnLogin) {
      final user = authState.user;
      return user.role == 'manager' ? '/manager' : '/employee';
    }

    return null;
  }
}
