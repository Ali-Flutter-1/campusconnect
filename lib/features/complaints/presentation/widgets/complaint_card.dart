import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/complaint.dart';

ColorRamp _statusColor(String status) {
  switch (status) {
    case 'resolved':
      return AppColors.success;
    case 'in_progress':
      return AppColors.primary;
    default:
      return AppColors.warning;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'in_progress':
      return 'IN PROGRESS';
    case 'resolved':
      return 'RESOLVED';
    default:
      return 'PENDING';
  }
}

/// One complaint/feedback item with a status badge. Ports the RN complaint card.
class ComplaintCard extends StatelessWidget {
  const ComplaintCard({super.key, required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final color = _statusColor(complaint.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: AppTypography.inter(
                    size: AppTypography.md,
                    weight: AppTypography.semiBold,
                    color: surfaces.primaryText,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.s500.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _statusLabel(complaint.status),
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    weight: AppTypography.bold,
                    color: color.s400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'CC-${complaint.id.substring(0, 4).toUpperCase()} · '
            '${complaint.category} · '
            '${DateFormat('MMM d').format(complaint.createdAt)}',
            style: AppTypography.inter(
              size: AppTypography.xs,
              color: surfaces.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            complaint.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              size: AppTypography.base,
              color: surfaces.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
