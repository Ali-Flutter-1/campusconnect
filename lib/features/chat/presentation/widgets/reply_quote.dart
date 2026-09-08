import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/chat_message.dart';

/// The quoted strip shown above a reply — inside the bubble, and again in the
/// composer while a reply is being written. [onPrimary] renders it for the
/// primary-filled bubble of the user's own messages.
class ReplyQuote extends StatelessWidget {
  const ReplyQuote({
    super.key,
    required this.senderName,
    required this.content,
    this.deleted = false,
    this.onPrimary = false,
    this.onClose,
  });

  ReplyQuote.of(
    ReplyPreview preview, {
    Key? key,
    bool onPrimary = false,
  }) : this(
          key: key,
          senderName: preview.senderName,
          content: preview.content,
          deleted: preview.deleted,
          onPrimary: onPrimary,
        );

  final String senderName;
  final String content;
  final bool deleted;
  final bool onPrimary;

  /// When set, a dismiss button is shown (composer usage).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final accent =
        onPrimary ? AppColors.white.withValues(alpha: 0.9) : AppColors.primary.s400;
    final body = onPrimary
        ? AppColors.white.withValues(alpha: 0.75)
        : surfaces.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: onPrimary
            ? AppColors.white.withValues(alpha: 0.14)
            : surfaces.cardBorder,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    weight: AppTypography.semiBold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  deleted ? 'Message deleted' : content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    color: body,
                  ).copyWith(
                    fontStyle: deleted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(Icons.close, size: 16, color: body),
              ),
            ),
        ],
      ),
    );
  }
}
