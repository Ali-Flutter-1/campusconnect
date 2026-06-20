import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular avatar that falls back to the first initial of a name, used in chat
/// bubbles and the profile header. Ports the RN `avatar` / `avatarText` styles.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.size = 32,
    this.backgroundColor,
  });

  final String name;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.s500,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTypography.inter(
          size: size * 0.42,
          weight: AppTypography.semiBold,
          color: AppColors.white,
        ),
      ),
    );
  }
}
