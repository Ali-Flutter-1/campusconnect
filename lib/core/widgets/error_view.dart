import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_spacing.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Full-screen error state with a retry action — shown when a BLoC emits an
/// error (e.g. the NetworkFailure path).
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = LucideIcons.alertCircle,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: surfaces.secondaryText),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                size: AppTypography.md,
                weight: AppTypography.medium,
                color: surfaces.primaryText,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Try again',
                icon: LucideIcons.refreshCw,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
