import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/category_badge.dart';
import '../../../../core/widgets/network_image_box.dart';
import '../../domain/entities/announcement.dart';

/// One announcement row: category + date, title, body, and like/bookmark
/// actions. Ports the RN announcement card. Admins additionally get a delete
/// action via [onDelete].
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLike,
    required this.onBookmark,
    this.onEdit,
    this.onDelete,
  });

  final Announcement announcement;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (announcement.imageUrl != null) ...[
            NetworkImageBox(url: announcement.imageUrl!, height: 150),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              CategoryBadge(label: announcement.category),
              const Spacer(),
              Text(
                DateFormat('MMM d').format(announcement.createdAt),
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
                _DeleteButton(onDelete: onDelete!, color: surfaces.secondaryText),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            announcement.title,
            style: AppTypography.inter(
              size: AppTypography.md,
              weight: AppTypography.semiBold,
              color: surfaces.primaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            announcement.content,
            style: AppTypography.inter(
              size: AppTypography.base,
              color: surfaces.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: surfaces.divider),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _ActionButton(
                icon: LucideIcons.heart,
                color: isLiked ? AppColors.error.s500 : surfaces.secondaryText,
                count: announcement.likes,
                onTap: onLike,
              ),
              const SizedBox(width: AppSpacing.lg),
              _ActionButton(
                icon: LucideIcons.bookmark,
                color: isBookmarked
                    ? AppColors.primary.s500
                    : surfaces.secondaryText,
                count: announcement.bookmarks,
                onTap: onBookmark,
              ),
              const Spacer(),
              Text(
                announcement.author,
                style: AppTypography.inter(
                  size: AppTypography.xs,
                  color: surfaces.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            // A filled state is conveyed via color; lucide has single-weight icons.
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: AppTypography.inter(
                size: AppTypography.xs,
                weight: AppTypography.medium,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onDelete, required this.color});
  final VoidCallback onDelete;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(LucideIcons.trash2, size: 16, color: color),
      onPressed: onDelete,
      tooltip: 'Delete',
    );
  }
}
