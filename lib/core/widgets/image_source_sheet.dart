import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/image_picking.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';

/// What the user chose in [showImageSourceSheet].
enum ImageSourceChoice { camera, gallery, remove }

extension ImageSourceChoiceX on ImageSourceChoice {
  /// The picker source for a choice that takes a new picture; null for
  /// [ImageSourceChoice.remove].
  ImagePickSource? get pickSource => switch (this) {
        ImageSourceChoice.camera => ImagePickSource.camera,
        ImageSourceChoice.gallery => ImagePickSource.gallery,
        ImageSourceChoice.remove => null,
      };
}

/// Asks whether to take a photo or choose an existing one, offering a remove
/// option when [canRemove]. Resolves to null if dismissed.
Future<ImageSourceChoice?> showImageSourceSheet(
  BuildContext context, {
  bool canRemove = false,
  String title = 'Add a photo',
}) {
  return showModalBottomSheet<ImageSourceChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final surfaces = context.surfaces;
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  title,
                  style: AppTypography.inter(
                    size: AppTypography.sm,
                    weight: AppTypography.semiBold,
                    color: surfaces.secondaryText,
                  ),
                ),
              ),
              _SourceTile(
                icon: LucideIcons.camera,
                label: 'Take a photo',
                onTap: () =>
                    Navigator.pop(context, ImageSourceChoice.camera),
              ),
              _SourceTile(
                icon: LucideIcons.image,
                label: 'Choose from gallery',
                onTap: () =>
                    Navigator.pop(context, ImageSourceChoice.gallery),
              ),
              if (canRemove)
                _SourceTile(
                  icon: LucideIcons.trash2,
                  label: 'Remove photo',
                  destructive: true,
                  onTap: () =>
                      Navigator.pop(context, ImageSourceChoice.remove),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
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
            Icon(icon, size: 19, color: color),
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
