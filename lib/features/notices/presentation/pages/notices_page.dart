import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/filter_pill.dart';
import '../../../../injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/notice.dart';
import '../bloc/notices_bloc.dart';
import '../widgets/create_notice_sheet.dart';
import '../widgets/notice_card.dart';

/// Notices screen — search, category filter, pinned + recent sections. Admins
/// can post and delete notices.
class NoticesPage extends StatelessWidget {
  const NoticesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NoticesBloc>(
      create: (_) => getIt<NoticesBloc>()..add(const NoticesLoadRequested()),
      child: const _NoticesView(),
    );
  }
}

class _NoticesView extends StatefulWidget {
  const _NoticesView();

  @override
  State<_NoticesView> createState() => _NoticesViewState();
}

class _NoticesViewState extends State<_NoticesView> {
  final _search = TextEditingController();
  static const _filters = ['all', 'exams', 'holidays', 'fees', 'events'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _onCreate(BuildContext context) async {
    final bloc = context.read<NoticesBloc>();
    final result = await CreateNoticeSheet.show(context);
    if (result != null) {
      bloc.add(NoticeCreated(
        title: result.title,
        content: result.content,
        category: result.category,
        priority: result.priority,
        department: result.department,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final isAdmin = context.select<AuthBloc, bool>((b) => b.state.isAdmin);

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _onCreate(context),
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'Notices',
                style: AppTypography.inter(
                  size: AppTypography.xxl,
                  weight: AppTypography.bold,
                  color: surfaces.primaryText,
                ),
              ),
            ),
            // Search.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _search,
                onChanged: (v) =>
                    context.read<NoticesBloc>().add(NoticesSearchChanged(v)),
                style: AppTypography.inter(
                  size: AppTypography.base,
                  color: surfaces.primaryText,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notices…',
                  hintStyle: AppTypography.inter(
                    size: AppTypography.base,
                    color: surfaces.secondaryText,
                  ),
                  prefixIcon:
                      Icon(LucideIcons.search, size: 18, color: surfaces.secondaryText),
                  filled: true,
                  fillColor: surfaces.cardBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: surfaces.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: surfaces.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide:
                        BorderSide(color: AppColors.primary.s500, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Filter pills.
            SizedBox(
              height: 44,
              child: BlocSelector<NoticesBloc, NoticesState, String>(
                selector: (s) => s.category,
                builder: (context, active) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final f = _filters[index];
                    return FilterPill(
                      label: '${f[0].toUpperCase()}${f.substring(1)}',
                      selected: active == f,
                      onTap: () => context
                          .read<NoticesBloc>()
                          .add(NoticesFilterChanged(f)),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: BlocConsumer<NoticesBloc, NoticesState>(
                listenWhen: (p, c) => p.errorMessage != c.errorMessage,
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                          SnackBar(content: Text(state.errorMessage!)));
                  }
                },
                builder: (context, state) {
                  switch (state.status) {
                    case NoticesStatus.initial:
                    case NoticesStatus.loading:
                      return const AppLoader();
                    case NoticesStatus.failure when state.notices.isEmpty:
                      return ErrorView(
                        message: state.errorMessage ?? 'Could not load notices.',
                        onRetry: () => context
                            .read<NoticesBloc>()
                            .add(const NoticesLoadRequested()),
                      );
                    case NoticesStatus.success:
                    case NoticesStatus.failure:
                      if (state.isEmpty) {
                        return const EmptyState(
                          icon: LucideIcons.fileText,
                          title: 'No notices found',
                          subtitle: 'Try a different category or search.',
                        );
                      }
                      return _NoticesList(state: state, isAdmin: isAdmin);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticesList extends StatelessWidget {
  const _NoticesList({required this.state, required this.isAdmin});

  final NoticesState state;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NoticesBloc>();
    final pinned = state.pinned;
    final recent = state.recent;

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const NoticesRefreshRequested()),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
            bloc.add(const NoticesLoadMoreRequested());
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            if (pinned.isNotEmpty) ...[
            const _SectionLabel(icon: LucideIcons.pin, label: 'PINNED'),
            for (var i = 0; i < pinned.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FadeSlideIn(
                  index: i,
                  child: NoticeCard(
                    notice: pinned[i],
                    onEdit:
                        isAdmin ? () => _onEdit(context, bloc, pinned[i]) : null,
                    onDelete: isAdmin
                        ? () => bloc.add(NoticeDeleted(pinned[i].id))
                        : null,
                  ),
                ),
              ),
          ],
          if (recent.isNotEmpty) ...[
            const _SectionLabel(icon: LucideIcons.clock, label: 'RECENT'),
            for (var i = 0; i < recent.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FadeSlideIn(
                  index: i,
                  child: NoticeCard(
                    notice: recent[i],
                    onEdit:
                        isAdmin ? () => _onEdit(context, bloc, recent[i]) : null,
                    onDelete: isAdmin
                        ? () => bloc.add(NoticeDeleted(recent[i].id))
                        : null,
                  ),
                ),
              ),
          ],
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onEdit(
    BuildContext context,
    NoticesBloc bloc,
    Notice n,
  ) async {
    final result = await CreateNoticeSheet.show(context, initial: n);
    if (result != null) {
      bloc.add(NoticeUpdated(
        id: n.id,
        title: result.title,
        content: result.content,
        category: result.category,
        priority: result.priority,
        department: result.department,
      ));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 13, color: surfaces.secondaryText),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.inter(
              size: AppTypography.xs,
              weight: AppTypography.semiBold,
              color: surfaces.secondaryText,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
