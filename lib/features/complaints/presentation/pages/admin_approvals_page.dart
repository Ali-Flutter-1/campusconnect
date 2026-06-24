import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/filter_pill.dart';
import '../../../../injection.dart';
import '../bloc/admin_complaints_bloc.dart';
import '../widgets/admin_complaint_card.dart';

/// Admin "Approvals" — review every student request and approve, resolve or
/// reject it. Mirrors the student "My Requests" screen but acts on all rows.
class AdminApprovalsPage extends StatelessWidget {
  const AdminApprovalsPage({super.key});

  static const _filters = [
    'all',
    'open',
    'in_progress',
    'resolved',
    'rejected',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminComplaintsBloc>(
      create: (_) => getIt<AdminComplaintsBloc>()
        ..add(const AdminComplaintsLoadRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Approvals')),
        body: SafeArea(
          child: BlocConsumer<AdminComplaintsBloc, AdminComplaintsState>(
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
                case AdminComplaintsStatus.initial:
                case AdminComplaintsStatus.loading:
                  return const AppLoader();
                case AdminComplaintsStatus.failure
                    when state.complaints.isEmpty:
                  return ErrorView(
                    message: state.errorMessage ?? 'Could not load requests.',
                    onRetry: () => context
                        .read<AdminComplaintsBloc>()
                        .add(const AdminComplaintsLoadRequested()),
                  );
                case AdminComplaintsStatus.success:
                case AdminComplaintsStatus.failure:
                  return _Body(state: state, filters: _filters);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.filters});

  final AdminComplaintsState state;
  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminComplaintsBloc>();
    // Filter once per build (the getter rebuilds the list on every read).
    final items = state.filtered;
    return RefreshIndicator(
      onRefresh: () async =>
          bloc.add(const AdminComplaintsRefreshRequested()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            children: [
              _StatCard(
                label: 'Pending',
                value: state.pendingCount,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatCard(
                label: 'Resolved',
                value: state.resolvedCount,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatCard(
                label: 'Total',
                value: state.total,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final f = filters[index];
                final label = f == 'in_progress'
                    ? 'In Progress'
                    : '${f[0].toUpperCase()}${f.substring(1)}';
                return FilterPill(
                  label: label,
                  selected: state.filter == f,
                  onTap: () => bloc.add(AdminComplaintsFilterChanged(f)),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(
                icon: LucideIcons.clipboardCheck,
                title: 'Nothing here',
                subtitle: 'No requests match this filter.',
              ),
            )
          else
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FadeSlideIn(
                  index: i,
                  child: AdminComplaintCard(
                    complaint: items[i],
                    onAction: (status) => bloc.add(
                      AdminComplaintStatusChanged(
                        id: items[i].id,
                        status: status,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final ColorRamp color;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: AppTypography.inter(
                size: AppTypography.xxl,
                weight: AppTypography.bold,
                color: color.s400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.inter(
                size: AppTypography.xs,
                color: surfaces.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
