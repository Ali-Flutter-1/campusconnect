import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';

/// A titled group of settings rows, drawn as one card with hairline dividers —
/// the shape used across Settings, Privacy and Help.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.footnote,
  });

  final String title;
  final List<Widget> children;

  /// Optional explanatory line under the card.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.inter(
              size: AppTypography.xs,
              weight: AppTypography.semiBold,
              color: surfaces.secondaryText,
            ).copyWith(letterSpacing: 0.8),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaces.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: surfaces.cardBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    color: surfaces.divider,
                  ),
                children[i],
              ],
            ],
          ),
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
              0,
            ),
            child: Text(
              footnote!,
              style: AppTypography.inter(
                size: AppTypography.sm,
                color: surfaces.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// One row inside a [SettingsSection]: an icon, a label, an optional subtitle
/// and either a [value] string, a trailing widget, or a chevron when tappable.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final tint = destructive ? surfaces.dangerText : surfaces.accentText;
    final labelColor =
        destructive ? surfaces.dangerText : surfaces.primaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: tint),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.inter(
                        size: AppTypography.base,
                        weight: AppTypography.medium,
                        color: labelColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.inter(
                          size: AppTypography.sm,
                          color: surfaces.secondaryText,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  value!,
                  style: AppTypography.inter(
                    size: AppTypography.sm,
                    color: surfaces.secondaryText,
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
              if (trailing == null && onTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: surfaces.secondaryText,
                ),
              ],
            ],
          ),
        ),
    );
  }
}

/// A block of explanatory prose inside a card — used by Privacy, where the
/// content is text rather than controls.
class SettingsProse extends StatelessWidget {
  const SettingsProse({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        text,
        style: AppTypography.inter(
          size: AppTypography.base,
          color: context.surfaces.primaryText,
          height: 1.5,
        ),
      ),
    );
  }
}
