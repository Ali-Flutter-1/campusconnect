import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';

/// Selectable rounded pill used for the events category filter row.
/// Ports the RN `filterPill` / `filterPillText` styles.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Material(
      color: selected ? AppColors.primary.s500 : surfaces.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: selected ? Colors.transparent : surfaces.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.inter(
              size: AppTypography.sm,
              weight: AppTypography.medium,
              color: selected ? AppColors.white : surfaces.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}
