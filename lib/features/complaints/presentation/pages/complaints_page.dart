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
import '../bloc/complaints_bloc.dart';
import '../widgets/complaint_card.dart';
import '../widgets/create_complaint_sheet.dart';

/// "My Submissions" — complaint/feedback tracking with summary stats, status
/// filter, and a button to file new feedback.
class ComplaintsPage extends StatelessWidget {
  const ComplaintsPage({super.key});

  static const _filters = ['all', 'open', 'in_progress', 'resolved'];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ComplaintsBloc>(
      create: (_) =>
          getIt<ComplaintsBloc>()..add(const ComplaintsLoadRequested()),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('My Submissions')),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_complaints',
            onPressed: () => _onCreate(context),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Feedback'),
          ),
          body: SafeArea(
            child: BlocConsumer<ComplaintsBloc, ComplaintsState>(
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
                  case ComplaintsStatus.initial:
                  case ComplaintsStatus.loading:
                    return const AppLoader();
                  case ComplaintsStatus.failure when state.complaints.isEmpty:
                    return ErrorView(
                      message:
                          state.errorMessage ?? 'Could not load submissions.',
                      onRetry: () => context
                          .read<ComplaintsBloc>()
                          .add(const ComplaintsLoadRequested()),
                    );
                  case ComplaintsStatus.success:
                  case ComplaintsStatus.failure:
                    return _Body(state: state, filters: _filters);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCreate(BuildContext context) async {
    final bloc = context.read<ComplaintsBloc>();
    final result = await CreateComplaintSheet.show(context);
    if (result != null) {
      bloc.add(ComplaintCreated(
        title: result.title,
        description: result.description,
        category: result.category,
      ));
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.filters});

  final ComplaintsState state;
  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ComplaintsBloc>();
    return RefreshIndicator(
      onRefresh: () async => bloc.add(const ComplaintsRefreshRequested()),
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
                label: 'Active',
                value: state.activeCount,
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
                  onTap: () => bloc.add(ComplaintsFilterChanged(f)),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(
                icon: LucideIcons.clipboardList,
                title: 'No submissions',
                subtitle: 'Tap "Feedback" to share something with the campus team.',
              ),
            )
          else
            for (var i = 0; i < state.filtered.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FadeSlideIn(
                  index: i,
                  child: ComplaintCard(complaint: state.filtered[i]),
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
