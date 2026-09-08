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

/// Tap-a-message detail card: who sent it, when it was sent and last edited,
/// its delivery state, and the reaction breakdown.
Future<void> showMessageDetailsSheet(
  BuildContext context, {
  required ChatMessage message,
  required bool isMine,
  required String? currentUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _MessageDetailsSheet(
      message: message,
      isMine: isMine,
      currentUserId: currentUserId,
    ),
  );
}

class _MessageDetailsSheet extends StatelessWidget {
  const _MessageDetailsSheet({
    required this.message,
    required this.isMine,
    required this.currentUserId,
  });

  final ChatMessage message;
  final bool isMine;
  final String? currentUserId;

  static final _full = DateFormat('EEEE, d MMMM y • h:mm a');

  String get _status {
    if (message.failed) return 'Not sent — tap the bubble to retry';
    if (message.pending) return 'Sending…';
    if (message.isDeleted) return 'Deleted';
    return 'Sent';
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final reactionCount =
        message.reactions.values.fold<int>(0, (sum, ids) => sum + ids.length);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: surfaces.scaffoldBackground,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: surfaces.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarCircle(name: message.senderName, size: 44),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMine ? 'You' : message.senderName,
                        style: AppTypography.inter(
                          size: AppTypography.md,
                          weight: AppTypography.semiBold,
                          color: surfaces.primaryText,
                        ),
                      ),
                      Text(
                        message.senderId == null
                            ? 'Account removed'
                            : 'in #${message.room}',
                        style: AppTypography.inter(
                          size: AppTypography.sm,
                          color: surfaces.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!message.isDeleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: surfaces.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: surfaces.cardBorder),
                ),
                child: Text(
                  message.content,
                  style: AppTypography.inter(
                    size: AppTypography.base,
                    color: surfaces.primaryText,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _DetailRow(
              icon: LucideIcons.clock,
              label: 'Sent',
              value: _full.format(message.createdAt),
            ),
            if (message.isEdited)
              _DetailRow(
                icon: LucideIcons.pencil,
                label: 'Edited',
                value: _full.format(message.editedAt!),
              ),
            if (message.isDeleted)
              _DetailRow(
                icon: LucideIcons.trash2,
                label: 'Deleted',
                value: _full.format(message.deletedAt!),
              ),
            _DetailRow(
              icon: LucideIcons.checkCheck,
              label: 'Status',
              value: _status,
            ),
            if (message.replyTo != null)
              _DetailRow(
                icon: LucideIcons.reply,
                label: 'Replying to',
                value: message.replyTo!.deleted
                    ? '${message.replyTo!.senderName} (deleted message)'
                    : message.replyTo!.senderName,
              ),
            if (reactionCount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reactions ($reactionCount)',
                style: AppTypography.inter(
                  size: AppTypography.sm,
                  weight: AppTypography.semiBold,
                  color: surfaces.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final entry in message.reactions.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: surfaces.cardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: surfaces.cardBorder),
                      ),
                      child: Text(
                        '${entry.key} ${entry.value.length}'
                        '${entry.value.contains(currentUserId) ? ' · you' : ''}',
                        style: AppTypography.inter(
                          size: AppTypography.sm,
                          color: surfaces.primaryText,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primary.s400),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: AppTypography.inter(
                size: AppTypography.sm,
                color: surfaces.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.inter(
                size: AppTypography.sm,
                weight: AppTypography.medium,
                color: surfaces.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
