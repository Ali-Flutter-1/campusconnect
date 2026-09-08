import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_emojis.dart';

/// What the user picked in the long-press sheet. [react] carries the chosen
/// emoji in [MessageAction.emoji].
enum MessageActionKind { react, reply, edit, copy, delete, details }

class MessageAction {
  const MessageAction(this.kind, {this.emoji});
  final MessageActionKind kind;
  final String? emoji;
}

/// Long-press menu for a message: a quick-reaction row on top, then reply /
/// copy / details, plus edit and delete for the user's own messages.
///
/// Resolves to the chosen [MessageAction], or null if dismissed.
Future<MessageAction?> showMessageActionsSheet(
  BuildContext context, {
  required ChatMessage message,
  required bool isMine,
  required String? currentUserId,
}) {
  return showModalBottomSheet<MessageAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _MessageActionsSheet(
      message: message,
      isMine: isMine,
      currentUserId: currentUserId,
    ),
  );
}

class _MessageActionsSheet extends StatelessWidget {
  const _MessageActionsSheet({
    required this.message,
    required this.isMine,
    required this.currentUserId,
  });

  final ChatMessage message;
  final bool isMine;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    // A deleted message has no text to react to, quote or copy; a pending one
    // has no server-side id yet, so it can only be inspected.
    final actionable = !message.isDeleted && !message.pending;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaces.scaffoldBackground,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: surfaces.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actionable) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final emoji in kQuickReactions)
                      _EmojiButton(
                        emoji: emoji,
                        selected: message.hasReaction(emoji, currentUserId),
                        onTap: () => Navigator.pop(
                          context,
                          MessageAction(MessageActionKind.react, emoji: emoji),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: surfaces.divider),
            ],
            if (actionable)
              _ActionTile(
                icon: LucideIcons.reply,
                label: 'Reply',
                onTap: () => Navigator.pop(
                  context,
                  const MessageAction(MessageActionKind.reply),
                ),
              ),
            if (actionable && isMine)
              _ActionTile(
                icon: LucideIcons.pencil,
                label: 'Edit',
                onTap: () => Navigator.pop(
                  context,
                  const MessageAction(MessageActionKind.edit),
                ),
              ),
            if (actionable)
              _ActionTile(
                icon: LucideIcons.copy,
                label: 'Copy text',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(
                    context,
                    const MessageAction(MessageActionKind.copy),
                  );
                },
              ),
            _ActionTile(
              icon: LucideIcons.info,
              label: 'Details',
              onTap: () => Navigator.pop(
                context,
                const MessageAction(MessageActionKind.details),
              ),
            ),
            if (isMine && !message.isDeleted)
              _ActionTile(
                icon: LucideIcons.trash2,
                label: 'Delete',
                destructive: true,
                onTap: () => Navigator.pop(
                  context,
                  const MessageAction(MessageActionKind.delete),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppColors.primary.s500.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? AppColors.error.s400 : context.surfaces.primaryText;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.inter(
                size: AppTypography.base,
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
