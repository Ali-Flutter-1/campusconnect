import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../injection.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A thin banner that slides in at the top of the app whenever the device loses
/// internet, reassuring the user that cached data is being shown. Driven by the
/// shared [InternetConnection] connectivity stream.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InternetStatus>(
      stream: getIt<InternetConnection>().onStatusChange,
      builder: (context, snapshot) {
        final offline = snapshot.data == InternetStatus.disconnected;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => SizeTransition(
            sizeFactor: anim,
            axisAlignment: -1,
            child: child,
          ),
          child: offline ? const _Bar() : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning.s700,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.wifiOff, size: 14, color: AppColors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                "You're offline — showing saved data",
                style: AppTypography.inter(
                  size: AppTypography.sm,
                  weight: AppTypography.medium,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
