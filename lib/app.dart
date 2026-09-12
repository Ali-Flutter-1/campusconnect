import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection.dart';

/// Root widget: provides the app-wide [AuthBloc], wires the router and the
/// app theme. The app is light-only — every screen sits on the near-white
/// scaffold, so the theme is pinned rather than following the system setting.
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
        // Light-only: every screen sits on the near-white scaffold.
        theme: AppTheme.light,
        darkTheme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
        // Overlay a top "offline" banner above whatever route is showing.
        // Most screens draw their own header instead of an AppBar, so the
        // status-bar style is set here rather than left to AppBarTheme.
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
