import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular avatar. Shows [imageUrl] when provided (with a graceful fallback to
/// the name's first initial), otherwise just the initial. Used in the profile
/// header, home header and chat bubbles.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 32,
    this.backgroundColor,
    this.loadingPlaceholder = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  /// When true, shows a spinner while the network image loads (instead of the
  /// initials) — used for the large profile avatar after an upload.
  final bool loadingPlaceholder;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    final fallback = Container(
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

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    final spinner = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (backgroundColor ?? AppColors.primary.s500)
            .withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: size * 0.36,
        height: size * 0.36,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
        ),
      ),
    );

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => loadingPlaceholder ? spinner : fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
