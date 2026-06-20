import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Small uppercase pill used for categories / priorities (announcements,
/// events, notices). Ports the RN `categoryBadge` + `categoryText` styles,
/// where the background is the tint color at ~8% opacity.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.label,
    this.color = AppColors.primary,
  });

  final String label;
  final ColorRamp color;

  @override
  Widget build(BuildContext context) {
    final tint = color.s500;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.inter(
          size: AppTypography.xs,
          weight: AppTypography.semiBold,
          color: tint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
