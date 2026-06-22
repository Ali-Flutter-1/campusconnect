import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/network_image_box.dart';
import '../../domain/entities/event.dart';

/// Maps an event category to its accent ramp (used for the date badge + tag).
ColorRamp eventCategoryColor(String category) {
  switch (category) {
    case 'academic':
      return AppColors.primary;
    case 'social':
      return AppColors.tertiary;
    case 'sports':
      return AppColors.success;
    default:
      return AppColors.warning;
  }
}

/// One event card: optional banner image, gradient date badge, category tag,
/// title, description and time/location. Admins get a delete action.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onEdit,
    this.onDelete,
  });

  final Event event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final color = eventCategoryColor(event.category);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl != null) ...[
            NetworkImageBox(url: event.imageUrl!, height: 140),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(date: event.date, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        event.category.toUpperCase(),
                        style: AppTypography.inter(
                          size: AppTypography.xs,
                          weight: AppTypography.semiBold,
                          color: color.s400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: AppTypography.inter(
                        size: AppTypography.lg,
                        weight: AppTypography.semiBold,
                        color: surfaces.primaryText,
                        height: 1.25,
                      ),
                    ),
                  ],
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
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                size: AppTypography.sm,
                color: surfaces.secondaryText,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Meta(icon: LucideIcons.clock, label: event.time),
              const SizedBox(width: AppSpacing.lg),
              Flexible(
                child: _Meta(icon: LucideIcons.mapPin, label: event.location),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date, required this.color});

  final DateTime date;
  final ColorRamp color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.s500, color.s700],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: AppTypography.inter(
              size: AppTypography.xs,
              weight: AppTypography.semiBold,
              color: AppColors.white,
            ),
          ),
          Text(
            '${date.day}',
            style: AppTypography.inter(
              size: AppTypography.xl,
              weight: AppTypography.bold,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: surfaces.secondaryText),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              size: AppTypography.xs,
              color: surfaces.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}
