import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/announcement.dart';
import '../bloc/announcements_bloc.dart';
import '../widgets/announcement_card.dart';
import '../widgets/create_announcement_sheet.dart';

/// Announcements screen. Students can like/bookmark; admins additionally see a
/// "+" button to publish and a delete action on each card (role gating).
class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AnnouncementsBloc>(
      create: (_) =>
          getIt<AnnouncementsBloc>()..add(const AnnouncementsLoadRequested()),
      child: const _AnnouncementsView(),
    );
  }
}

class _AnnouncementsView extends StatelessWidget {
  const _AnnouncementsView();

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthBloc, bool>((b) => b.state.isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.megaphone, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Announcements',
              style: AppTypography.inter(
                size: AppTypography.xl,
                weight: AppTypography.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _onCreate(context),
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: BlocConsumer<AnnouncementsBloc, AnnouncementsState>(
        listenWhen: (p, c) => p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case AnnouncementsStatus.initial:
            case AnnouncementsStatus.loading:
              return const AppLoader();
            case AnnouncementsStatus.failure when state.announcements.isEmpty:
              return ErrorView(
                message: state.errorMessage ?? 'Could not load announcements.',
                onRetry: () => context
                    .read<AnnouncementsBloc>()
                    .add(const AnnouncementsLoadRequested()),
              );
            case AnnouncementsStatus.success:
            case AnnouncementsStatus.failure:
              if (state.announcements.isEmpty) {
                return const EmptyState(
                  icon: LucideIcons.megaphone,
                  title: 'No announcements yet',
                  subtitle: 'Check back soon for campus updates.',
                );
              }
              return _List(isAdmin: isAdmin);
          }
        },
      ),
    );
  }

  Future<void> _onCreate(BuildContext context) async {
    final bloc = context.read<AnnouncementsBloc>();
    final author = context.read<AuthBloc>().state.user?.displayName ?? 'Admin';
    final result = await CreateAnnouncementSheet.show(context);
    if (result != null) {
      bloc.add(AnnouncementCreated(
        title: result.title,
        content: result.content,
        category: result.category,
        author: author,
        imageBytes: result.image?.bytes,
        imageExt: result.image?.ext,
      ));
    }
  }
}

class _List extends StatelessWidget {
  const _List({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AnnouncementsBloc>();
    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const AnnouncementsRefreshRequested());
      },
      child: BlocBuilder<AnnouncementsBloc, AnnouncementsState>(
        builder: (context, state) {
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                bloc.add(const AnnouncementsLoadMoreRequested());
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount:
                  state.announcements.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index >= state.announcements.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final a = state.announcements[index];
                return FadeSlideIn(
                  index: index < AppConstants.pageSize ? index : 0,
                  child: AnnouncementCard(
                    announcement: a,
                    isLiked: state.isLiked(a.id),
                    isBookmarked: state.isBookmarked(a.id),
                    onLike: () => bloc.add(AnnouncementLikeToggled(a.id)),
                    onBookmark: () =>
                        bloc.add(AnnouncementBookmarkToggled(a.id)),
                    onEdit: isAdmin ? () => _onEdit(context, bloc, a) : null,
                    onDelete: isAdmin
                        ? () => bloc.add(AnnouncementDeleted(a.id))
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _onEdit(
    BuildContext context,
    AnnouncementsBloc bloc,
    Announcement a,
  ) async {
    final result = await CreateAnnouncementSheet.show(context, initial: a);
    if (result != null) {
      bloc.add(AnnouncementUpdated(
        id: a.id,
        title: result.title,
        content: result.content,
        category: result.category,
      ));
    }
  }
}
