import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:parkflow_manager/features/auth/presentation/pages/login_page.dart';
import 'package:parkflow_manager/features/employee_management/presentation/pages/employee_management_page.dart';
import 'package:parkflow_manager/features/parking_session/presentation/pages/employee_dashboard_page.dart';
import 'package:parkflow_manager/features/reports/presentation/pages/manager_dashboard_page.dart';
import 'package:parkflow_manager/features/lot_map/presentation/pages/lot_map_page.dart';
import 'package:parkflow_manager/features/payment/presentation/pages/checkout_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false, // Disabled — prevents route info leaking in logs
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ──────────── Employee Routes ────────────
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
              final raw = state.pathParameters['sessionId'];
              final sessionId = int.tryParse(raw ?? '');
              if (sessionId == null) {
                // Guard against tampered/malformed route params
                return const Scaffold(
                  body: Center(child: Text('Invalid session')),
                );
              }
              return CheckoutPage(sessionId: sessionId);
            },
          ),
        ],
      ),

      // ──────────── Manager Routes ────────────
      GoRoute(
        path: '/manager',
        name: 'manager-dashboard',
        builder: (context, state) => const ManagerDashboardPage(),
        routes: [
          GoRoute(
            path: 'employees',
            name: 'employee-management',
            builder: (context, state) {
              // lotId comes from the authenticated user's assigned lot
              final authState = authBloc.state;
              final lotId = authState is AuthAuthenticated
                  ? (authState.user.assignedLotId ?? 'default')
                  : 'default';
              return EmployeeManagementPage(lotId: lotId);
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

    // Unauthenticated users can only access /login
    if (authState is AuthUnauthenticated && !isOnLogin) {
      return '/login';
    }

    // Authenticated users on /login get redirected to their dashboard
    if (authState is AuthAuthenticated && isOnLogin) {
      return authState.user.role == 'manager' ? '/manager' : '/employee';
    }

    // Enforce role-based route access
    if (authState is AuthAuthenticated) {
      final role = authState.user.role;
      if (role == 'employee' && location.startsWith('/manager')) {
        return '/employee'; // Employees cannot access manager routes
      }
      if (role == 'manager' && location.startsWith('/employee')) {
        // Managers CAN access employee routes (they may need to demo/inspect)
        return null;
      }
    }

    return null;
  }
}
