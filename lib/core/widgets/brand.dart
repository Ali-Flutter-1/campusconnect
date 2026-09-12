import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';

/// The three brand marks that ship with the app. [appIcon] is the launcher
/// icon, so it is the one to use anywhere the app identifies itself; the other
/// two are alternates for surfaces that would otherwise repeat it.
enum BrandVariant {
  /// Network-and-bubble mark — matches the installed launcher icon.
  appIcon('assets/images/app_icon.png'),

  /// Monogram "C" built from concentric arcs.
  cMark('assets/images/logo_c_mark.png'),

  /// Enclosing "C" holding two chat bubbles.
  bubbleNode('assets/images/logo_bubble_node.png');

  const BrandVariant(this.asset);

  final String asset;
}

/// The CampusConnect app mark: the brand logo in a frosted rounded tile.
///
/// The artwork carries its own deep-navy ground, so the tile is clipped to the
/// same rounded-square silhouette as the launcher icon and reads as an app tile
/// on both light and dark surfaces.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 96,
    this.variant = BrandVariant.appIcon,
  });

  final double size;
  final BrandVariant variant;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final isDark = context.isDark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        // A colored glow reads as a highlight against navy but looks dated on
        // white, where a plain drop shadow lifts the tile instead.
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.primary.s500.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: size * (isDark ? 0.25 : 0.18),
            offset: Offset(0, isDark ? 0 : size * 0.04),
            spreadRadius: isDark ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          variant.asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// The "CampusConnect" wordmark — "Campus" in white, "Connect" in primary.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 32});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Campus',
            style: AppTypography.inter(
              size: fontSize,
              weight: AppTypography.bold,
              color: context.surfaces.primaryText,
            ),
          ),
          TextSpan(
            text: 'Connect',
            style: AppTypography.inter(
              size: fontSize,
              weight: AppTypography.bold,
              color: context.surfaces.accentText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen dark-blue gradient used by the splash/onboarding/auth screens.
class BrandGradient extends StatelessWidget {
  const BrandGradient({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Expand to fill the whole screen — otherwise the gradient would only cover
    // the width of its (narrow, centered) child, leaving the sides blank.
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEFF4FF), // faint primary tint
            Color(0xFFF7F9FC),
            Color(0xFFFAFAFA), // neutral[50] — the scaffold color
          ],
        ),
      ),
      child: child,
    );
  }
}
