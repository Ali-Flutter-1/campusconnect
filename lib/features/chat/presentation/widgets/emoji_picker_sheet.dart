import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import 'chat_emojis.dart';

/// The full reaction palette, opened from the "+" in the message action sheet.
/// Resolves to the chosen emoji, or null if dismissed.
///
/// [selected] are the emoji the current user has already put on the message, so
/// tapping one reads as "remove it" rather than a no-op.
Future<String?> showEmojiPickerSheet(
  BuildContext context, {
  Set<String> selected = const {},
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _EmojiPickerSheet(selected: selected),
  );
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({required this.selected});

  final Set<String> selected;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        // Tall enough to browse, short enough to leave the message visible.
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: surfaces.scaffoldBackground,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: surfaces.cardBorder),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Pick a reaction',
                    style: AppTypography.inter(
                      size: AppTypography.base,
                      weight: AppTypography.semiBold,
                      color: surfaces.primaryText,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: surfaces.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: surfaces.divider),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  for (final category in kEmojiCategories) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xs,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          category.name.toUpperCase(),
                          style: AppTypography.inter(
                            size: AppTypography.xs,
                            weight: AppTypography.semiBold,
                            color: surfaces.secondaryText,
                          ).copyWith(letterSpacing: 0.8),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 52,
                          childAspectRatio: 1,
                        ),
                        itemCount: category.emojis.length,
                        itemBuilder: (context, i) {
                          final emoji = category.emojis[i];
                          return _EmojiCell(
                            emoji: emoji,
                            selected: selected.contains(emoji),
                            onTap: () => Navigator.pop(context, emoji),
                          );
                        },
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiCell extends StatelessWidget {
  const _EmojiCell({
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
        margin: const EdgeInsets.all(2),
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
