import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/brand.dart';

/// Branded entry screen (the "Splash Screen" mockup). Shown to signed-out users;
/// "Get Started" takes them to sign-in.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandGradient(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                const BrandMark()
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack)
                    .fadeIn(),
                const SizedBox(height: AppSpacing.xl),
                const BrandWordmark()
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 400.ms)
                    .moveY(begin: 12, end: 0),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Navigating university life,\nsimplified and unified.',
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    size: AppTypography.md,
                    color: AppColors.secondary.s300,
                    height: 1.5,
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                const Spacer(),
                Text(
                  '© 2024 UNIVERSITY ECOSYSTEM',
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    weight: AppTypography.semiBold,
                    color: AppColors.secondary.s500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _GetStartedButton(onTap: () => context.go(AppRoutes.login))
                    .animate(delay: 450.ms)
                    .fadeIn(duration: 400.ms)
                    .moveY(begin: 16, end: 0),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.s500,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          width: 220,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'GET STARTED',
            style: AppTypography.inter(
              size: AppTypography.base,
              weight: AppTypography.bold,
              color: AppColors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
