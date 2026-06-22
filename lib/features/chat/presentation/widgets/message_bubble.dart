import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../domain/entities/chat_message.dart';

/// A single chat bubble. My messages align right (primary fill); others align
/// left with the sender's avatar + name. Ports the RN chat bubble styling.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final time = DateFormat('h:mm a').format(message.createdAt);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary.s500 : surfaces.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.lg),
          topRight: const Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(isMine ? AppRadius.lg : 4),
          bottomRight: Radius.circular(isMine ? 4 : AppRadius.lg),
        ),
        border: isMine ? null : Border.all(color: surfaces.cardBorder),
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Text(
              message.senderName,
              style: AppTypography.inter(
                size: AppTypography.xs,
                weight: AppTypography.semiBold,
                color: AppColors.primary.s400,
              ),
            ),
          if (!isMine) const SizedBox(height: 2),
          Text(
            message.content,
            style: AppTypography.inter(
              size: AppTypography.base,
              color: isMine ? AppColors.white : surfaces.primaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: AppTypography.inter(
              size: AppTypography.xs,
              color: isMine
                  ? AppColors.white.withValues(alpha: 0.7)
                  : surfaces.secondaryText,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            AvatarCircle(name: message.senderName, size: 30),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
