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
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/category_badge.dart';
import '../../../../injection.dart';
import '../../../announcements/domain/entities/announcement.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../events/presentation/widgets/event_card.dart';
import '../../../polls/presentation/widgets/poll_card.dart';
import '../bloc/home_bloc.dart';

/// Student Home feed — greeting, quick actions, latest announcements, the
/// active poll and upcoming events. Matches the "Home Dashboard" mockup.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => getIt<HomeBloc>()..add(const HomeLoadRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state.status == HomeStatus.initial ||
                state.status == HomeStatus.loading) {
              return const AppLoader();
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<HomeBloc>().add(const HomeRefreshRequested()),
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  const _Header(),
                  const SizedBox(height: AppSpacing.md),
                  const _QuickActions(),
                  if (state.announcements.isNotEmpty) ...[
                    _SectionHeader(
                      icon: LucideIcons.megaphone,
                      title: 'Latest Announcements',
                      onSeeAll: () => context.push(AppRoutes.announcements),
                    ),
                    _AnnouncementStrip(announcements: state.announcements),
                  ],
                  if (state.polls.isNotEmpty) ...[
                    _SectionHeader(
                      icon: LucideIcons.barChart3,
                      title: 'Active Poll',
                      onSeeAll: () => context.push(AppRoutes.polls),
                      actionLabel: 'Vote Now',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: PollCard(
                        poll: state.polls.first,
                        votedIndex: -1, // results view; voting happens on /polls
                        onVote: (_) => context.push(AppRoutes.polls),
                      ),
                    ),
                  ],
                  if (state.events.isNotEmpty) ...[
                    _SectionHeader(
                      icon: LucideIcons.calendar,
                      title: 'Upcoming Events',
                      onSeeAll: () => context.go(AppRoutes.events),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          for (final e in state.events)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _EventTile(
                                title: e.title,
                                date: e.date,
                                time: e.time,
                                location: e.location,
                                category: e.category,
                                onTap: () => context.go(AppRoutes.events),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final name = context.select<AuthBloc, String>(
      (b) => b.state.user?.displayName ?? 'Student',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: AppTypography.inter(
                    size: AppTypography.sm,
                    color: surfaces.secondaryText,
                  ),
                ),
                Text(
                  name,
                  style: AppTypography.inter(
                    size: AppTypography.xl,
                    weight: AppTypography.bold,
                    color: surfaces.primaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Icon(LucideIcons.bell, color: surfaces.primaryText),
          ),
          const SizedBox(width: AppSpacing.sm),
          AvatarCircle(name: name, size: 40),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final ColorRamp color;
  final VoidCallback onTap;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(LucideIcons.megaphone, 'Announce', AppColors.primary,
          () => context.push(AppRoutes.announcements)),
      _QuickAction(LucideIcons.calendar, 'Events', AppColors.tertiary,
          () => context.go(AppRoutes.events)),
      _QuickAction(LucideIcons.barChart3, 'Polls', AppColors.success,
          () => context.push(AppRoutes.polls)),
      _QuickAction(LucideIcons.messageSquare, 'Chat', AppColors.accent,
          () => context.go(AppRoutes.chat)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: _QuickActionTile(action: actions[i])),
          ],
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return AppCard(
      onTap: action.onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: action.color.s500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(action.icon, color: action.color.s400, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            action.label,
            style: AppTypography.inter(
              size: AppTypography.xs,
              weight: AppTypography.medium,
              color: surfaces.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onSeeAll,
    this.actionLabel = 'See All',
  });

  final IconData icon;
  final String title;
  final VoidCallback onSeeAll;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.s400),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTypography.inter(
                size: AppTypography.lg,
                weight: AppTypography.semiBold,
                color: surfaces.primaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              actionLabel,
              style: AppTypography.inter(
                size: AppTypography.sm,
                weight: AppTypography.medium,
                color: AppColors.primary.s400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementStrip extends StatelessWidget {
  const _AnnouncementStrip({required this.announcements});

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: announcements.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final a = announcements[index];
          return FadeSlideIn(
            index: index,
            child: SizedBox(
              width: 260,
              child: AppCard(
                onTap: () => context.push(AppRoutes.announcements),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryBadge(label: a.category),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        size: AppTypography.md,
                        weight: AppTypography.semiBold,
                        color: surfaces.primaryText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        a.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          size: AppTypography.sm,
                          color: surfaces.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    required this.onTap,
  });

  final String title;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final color = eventCategoryColor(category);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.s500, color.s700]),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '${date.day}',
              style: AppTypography.inter(
                size: AppTypography.lg,
                weight: AppTypography.bold,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    size: AppTypography.base,
                    weight: AppTypography.semiBold,
                    color: surfaces.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time · $location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    size: AppTypography.xs,
                    color: surfaces.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 18, color: surfaces.secondaryText),
        ],
      ),
    );
  }
}
