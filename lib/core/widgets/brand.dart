import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The CampusConnect app mark: a frosted rounded tile holding a gradient
/// check-circle, as in the splash mockup.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Container(
          width: size * 0.6,
          height: size * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent.s400, AppColors.primary.s500],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.s500.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(LucideIcons.check, color: AppColors.white, size: size * 0.3),
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
              color: AppColors.white,
            ),
          ),
          TextSpan(
            text: 'Connect',
            style: AppTypography.inter(
              size: fontSize,
              weight: AppTypography.bold,
              color: AppColors.primary.s400,
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
            Color(0xFF111E3A), // deep navy
            Color(0xFF0B1326),
            Color(0xFF0F172A), // secondary[900]
          ],
        ),
      ),
      child: child,
    );
  }
}
