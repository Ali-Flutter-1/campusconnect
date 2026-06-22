import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/notice.dart';

/// Maps a notice category to its accent ramp.
ColorRamp noticeCategoryColor(String category) {
  switch (category) {
    case 'exams':
      return AppColors.primary;
    case 'holidays':
      return AppColors.success;
    case 'fees':
      return AppColors.warning;
    case 'events':
      return AppColors.tertiary;
    default:
      return AppColors.accent;
  }
}

/// One notice: category badge, time, title, content and department footer.
/// Pinned notices show a pin icon. Admins get a delete action.
class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key, required this.notice, this.onEdit, this.onDelete});

  final Notice notice;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final color = noticeCategoryColor(notice.category);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.s500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  notice.category.toUpperCase(),
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    weight: AppTypography.semiBold,
                    color: color.s400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (notice.isPinned) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(LucideIcons.pin, size: 13, color: AppColors.warning.s400),
              ],
              const Spacer(),
              Text(
                DateFormat('MMM d').format(notice.createdAt),
                style: AppTypography.inter(
                  size: AppTypography.xs,
                  color: surfaces.secondaryText,
                ),
              ),
              if (onEdit != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(LucideIcons.pencil,
                      size: 15, color: surfaces.secondaryText),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
              if (onDelete != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(LucideIcons.trash2,
                      size: 16, color: surfaces.secondaryText),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            notice.title,
            style: AppTypography.inter(
              size: AppTypography.md,
              weight: AppTypography.semiBold,
              color: surfaces.primaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notice.content,
            style: AppTypography.inter(
              size: AppTypography.base,
              color: surfaces.secondaryText,
              height: 1.5,
            ),
          ),
          if (notice.department != null && notice.department!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(LucideIcons.building2,
                    size: 13, color: surfaces.secondaryText),
                const SizedBox(width: 6),
                Text(
                  notice.department!,
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    weight: AppTypography.medium,
                    color: surfaces.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
