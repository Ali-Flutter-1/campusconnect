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
import '../../../../core/widgets/avatar_circle.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/edit_profile_sheet.dart';

/// Profile tab — identity card, account info, menu, and logout. Reads the
/// app-wide [AuthBloc] for the current user.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.user;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                FadeSlideIn(child: _Header(user: user)),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(index: 1, child: _IdentityCard(user: user)),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  index: 2,
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: LucideIcons.clipboardList,
                        label: 'My Requests',
                        onTap: () => context.push(AppRoutes.complaints),
                      ),
                      _MenuRow(
                        icon: LucideIcons.settings,
                        label: 'Settings',
                        onTap: () => _soon(context),
                      ),
                      _MenuRow(
                        icon: LucideIcons.shield,
                        label: 'Privacy',
                        onTap: () => _soon(context),
                      ),
                      _MenuRow(
                        icon: LucideIcons.helpCircle,
                        label: 'Help & Support',
                        onTap: () => _soon(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _LogoutButton(
                  onTap: () =>
                      context.read<AuthBloc>().add(const AuthSignOutRequested()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final subtitle = [user.course, user.department]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');

    // True while a profile save (incl. avatar upload) is in flight.
    final saving = context.select<AuthBloc, bool>((b) => b.state.isSubmitting);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AvatarCircle(
              name: user.displayName,
              imageUrl: user.avatarUrl,
              size: 92,
              loadingPlaceholder: true,
            ),
            // Upload-in-progress overlay.
            if (saving)
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: AppColors.primary.s500,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: saving ? null : () => EditProfileSheet.show(context),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(LucideIcons.pencil,
                        size: 14, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          user.displayName,
          style: AppTypography.inter(
            size: AppTypography.xxl,
            weight: AppTypography.bold,
            color: surfaces.primaryText,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.inter(
              size: AppTypography.base,
              color: surfaces.secondaryText,
            ),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          user.email,
          style: AppTypography.inter(
            size: AppTypography.sm,
            color: surfaces.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final id = 'CC-${user.id.substring(0, 8).toUpperCase()}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.s700, AppColors.secondary.s900],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                user.isAdmin ? 'ADMIN IDENTITY' : 'STUDENT IDENTITY',
                style: AppTypography.inter(
                  size: AppTypography.xs,
                  weight: AppTypography.semiBold,
                  color: AppColors.white.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.badgeCheck,
                  size: 18, color: AppColors.white.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            id,
            style: AppTypography.inter(
              size: AppTypography.xl,
              weight: AppTypography.bold,
              color: AppColors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _IdField(label: 'YEAR', value: user.year ?? '—'),
              const SizedBox(width: AppSpacing.xl),
              _IdField(label: 'ROLE', value: user.role.name.toUpperCase()),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.s500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'ACTIVE',
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    weight: AppTypography.bold,
                    color: AppColors.success.s300,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdField extends StatelessWidget {
  const _IdField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            size: AppTypography.xs,
            color: AppColors.white.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.inter(
            size: AppTypography.base,
            weight: AppTypography.semiBold,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: surfaces.primaryText),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.inter(
                  size: AppTypography.base,
                  weight: AppTypography.medium,
                  color: surfaces.primaryText,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18, color: surfaces.secondaryText),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.s500.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.logOut, size: 18, color: AppColors.error.s400),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Logout',
                style: AppTypography.inter(
                  size: AppTypography.base,
                  weight: AppTypography.semiBold,
                  color: AppColors.error.s400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
