import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection.dart';

/// Root widget: provides the app-wide [AuthBloc], wires the router and the
/// light/dark themes. The active theme follows the system setting (mirroring
/// the RN `useColorScheme()` behavior).
class ConnectApp extends StatelessWidget {
  const ConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      // Singleton bloc; start tracking the session immediately.
      value: getIt<AuthBloc>()..add(const AuthSubscriptionRequested()),
      child: MaterialApp.router(
        title: 'CampusConnect',
        debugShowCheckedModeBanner: false,
        // Dark-only, to match the "CampusConnect" mockups.
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
      ),
    );
  }
}
