import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../domain/entities/chat_message.dart';
import 'reaction_bar.dart';
import 'reply_quote.dart';

/// A single chat bubble. My messages align right (primary fill); others align
/// left with the sender's avatar + name. Offline messages show a "sending" clock
/// or, if the send failed, a tap-to-retry indicator.
///
/// Tap opens the message details, long-press (or the swipe-free chevron on a
/// failed send) opens the actions menu. Replies carry a quoted strip and any
/// reactions sit in a chip row beneath the bubble.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.currentUserId,
    this.onRetry,
    this.onTap,
    this.onLongPress,
    this.onToggleReaction,
  });

  final ChatMessage message;
  final bool isMine;
  final String? currentUserId;
  final VoidCallback? onRetry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onToggleReaction;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final time = DateFormat('h:mm a').format(message.createdAt);
    final mutedOnPrimary = AppColors.white.withValues(alpha: 0.7);
    final bodyColor = isMine ? AppColors.white : surfaces.primaryText;
    final metaColor = isMine ? mutedOnPrimary : surfaces.secondaryText;

    final bubble = Opacity(
      opacity: message.pending ? 0.7 : 1,
      child: Container(
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
                  color: surfaces.accentText,
                ),
              ),
            if (!isMine) const SizedBox(height: 2),
            if (message.replyTo != null) ...[
              ReplyQuote.of(message.replyTo!, onPrimary: isMine),
              const SizedBox(height: 4),
            ],
            if (message.isDeleted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.ban, size: 13, color: metaColor),
                  const SizedBox(width: 5),
                  Text(
                    'This message was deleted',
                    style: AppTypography.inter(
                      size: AppTypography.base,
                      color: metaColor,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              )
            else
              Text(
                message.content,
                style: AppTypography.inter(
                  size: AppTypography.base,
                  color: bodyColor,
                  height: 1.3,
                ),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.failed ? 'Failed — tap to retry' : time,
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    color:
                        message.failed ? AppColors.error.s300 : metaColor,
                  ),
                ),
                if (message.isEdited && !message.isDeleted) ...[
                  const SizedBox(width: 4),
                  Text(
                    '· edited',
                    style: AppTypography.inter(
                      size: AppTypography.xs,
                      color: metaColor,
                    ),
                  ),
                ],
                if (isMine && message.pending) ...[
                  const SizedBox(width: 4),
                  Icon(LucideIcons.clock, size: 11, color: mutedOnPrimary),
                ],
                if (isMine && message.failed) ...[
                  const SizedBox(width: 4),
                  Icon(LucideIcons.alertCircle,
                      size: 11, color: AppColors.error.s300),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                AvatarCircle(name: message.senderName, size: 30),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: GestureDetector(
                  // A failed send retries on tap; every other message opens its
                  // details instead.
                  onTap: message.failed ? onRetry : onTap,
                  onLongPress: onLongPress,
                  child: bubble,
                ),
              ),
            ],
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isMine ? 0 : 30 + AppSpacing.sm,
              ),
              child: ReactionBar(
                message: message,
                currentUserId: currentUserId,
                onToggle: onToggleReaction ?? (_) {},
              ),
            ),
        ],
      ),
    );
  }
}
