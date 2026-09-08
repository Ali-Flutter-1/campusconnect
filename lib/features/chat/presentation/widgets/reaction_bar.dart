import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/chat_message.dart';

/// The row of reaction chips under a bubble — one chip per emoji with its
/// count. The current user's own reactions are highlighted; tapping a chip
/// toggles that reaction.
class ReactionBar extends StatelessWidget {
  const ReactionBar({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onToggle,
  });

  final ChatMessage message;
  final String? currentUserId;
  final void Function(String emoji) onToggle;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final entries = message.reactions.entries
        .where((e) => e.value.isNotEmpty)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in entries)
          _Chip(
            emoji: entry.key,
            count: entry.value.length,
            mine: currentUserId != null && entry.value.contains(currentUserId),
            surfaces: surfaces,
            onTap: () => onToggle(entry.key),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.emoji,
    required this.count,
    required this.mine,
    required this.surfaces,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool mine;
  final AppSurfaces surfaces;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.primary.s500.withValues(alpha: 0.16)
              : surfaces.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: mine ? AppColors.primary.s400 : surfaces.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: AppTypography.inter(
                size: AppTypography.xs,
                weight: mine ? AppTypography.semiBold : AppTypography.regular,
                color: mine ? AppColors.primary.s400 : surfaces.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
