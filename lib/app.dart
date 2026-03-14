import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/di/injection.dart';
import 'package:parkflow_manager/core/router/app_router.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_event.dart';

class ParkFlowApp extends StatelessWidget {
  ParkFlowApp({super.key});

  late final _authBloc = getIt<AuthBloc>();
  late final _appRouter = AppRouter(authBloc: _authBloc);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc..add(const AuthCheckRequested())),
      ],
      child: MaterialApp.router(
        title: 'ParkFlow Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
