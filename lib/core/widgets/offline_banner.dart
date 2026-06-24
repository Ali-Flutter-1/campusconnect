import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../injection.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A thin banner that appears at the top of the app only when the device is
/// **confirmed** offline.
///
/// The connectivity checker emits a brief `disconnected` while it runs its first
/// network probe at launch, which would otherwise flash a false "offline" even
/// when online. So we debounce: we only show the banner if a disconnection
/// persists (re-verified after a short delay), and hide it instantly on connect.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final InternetConnection _connection = getIt<InternetConnection>();
  StreamSubscription<InternetStatus>? _sub;
  Timer? _debounce;
  bool _offline = false;

  static const _confirmDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _sub = _connection.onStatusChange.listen(_onStatus);
  }

  void _onStatus(InternetStatus status) {
    if (status == InternetStatus.connected) {
      _debounce?.cancel();
      if (_offline) setState(() => _offline = false);
      return;
    }
    // Disconnected: wait, then re-verify before showing (ignores startup blips).
    _debounce?.cancel();
    _debounce = Timer(_confirmDelay, () async {
      final hasAccess = await _connection.hasInternetAccess;
      if (!mounted) return;
      if (!hasAccess && !_offline) setState(() => _offline = true);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        axisAlignment: -1,
        child: child,
      ),
      child: _offline ? const _Bar() : const SizedBox.shrink(),
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
