import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Admin landing screen — a management hub, distinct from the student Home feed.
/// Shown as the first tab only for admins (role-aware shell).
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final name = context.select<AuthBloc, String>(
      (b) => b.state.user?.displayName ?? 'Admin',
    );

    final actions = <_AdminAction>[
      const _AdminAction(
        icon: LucideIcons.megaphone,
        label: 'Announcements',
        subtitle: 'Publish & remove',
        route: AppRoutes.announcements,
        color: AppColors.primary,
      ),
      const _AdminAction(
        icon: LucideIcons.calendar,
        label: 'Events',
        subtitle: 'Manage events',
        route: AppRoutes.events,
        color: AppColors.accent,
      ),
      const _AdminAction(
        icon: LucideIcons.barChart3,
        label: 'Polls',
        subtitle: 'Create polls',
        route: AppRoutes.polls,
        color: AppColors.success,
      ),
      const _AdminAction(
        icon: LucideIcons.fileText,
        label: 'Notices',
        subtitle: 'Post notices',
        route: AppRoutes.notices,
        color: AppColors.warning,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            FadeSlideIn(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: AppTypography.inter(
                            size: AppTypography.xxl,
                            weight: AppTypography.bold,
                            color: surfaces.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Welcome back, $name',
                          style: AppTypography.inter(
                            size: AppTypography.base,
                            color: surfaces.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _AdminBadge(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(
              index: 1,
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.3,
                children: [
                  for (final a in actions)
                    _ActionTile(action: a, onTap: () => context.push(a.route)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminAction {
  const _AdminAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final ColorRamp color;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final _AdminAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: action.color.s500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(action.icon, color: action.color.s500, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            action.label,
            style: AppTypography.inter(
              size: AppTypography.md,
              weight: AppTypography.semiBold,
              color: surfaces.primaryText,
            ),
          ),
          Text(
            action.subtitle,
            style: AppTypography.inter(
              size: AppTypography.xs,
              color: surfaces.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.s500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.primary.s500),
          const SizedBox(width: 4),
          Text(
            'ADMIN',
            style: AppTypography.inter(
              size: AppTypography.xs,
              weight: AppTypography.bold,
              color: AppColors.primary.s500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
