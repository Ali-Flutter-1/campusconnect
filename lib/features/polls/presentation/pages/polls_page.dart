import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/polls_bloc.dart';
import '../widgets/create_poll_sheet.dart';
import '../widgets/poll_card.dart';

/// Polls screen — list active polls, vote once, see live percentages.
class PollsPage extends StatelessWidget {
  const PollsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PollsBloc>(
      create: (_) => getIt<PollsBloc>()..add(const PollsLoadRequested()),
      child: Builder(
        builder: (context) {
          final isAdmin = context.select<AuthBloc, bool>((b) => b.state.isAdmin);
          return Scaffold(
            floatingActionButton: isAdmin
                ? FloatingActionButton(
                    heroTag: 'fab_polls',
                    onPressed: () => _onCreate(context),
                    child: const Icon(LucideIcons.plus),
                  )
                : null,
            appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.barChart3, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Polls',
                style: AppTypography.inter(
                  size: AppTypography.xl,
                  weight: AppTypography.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        body: BlocConsumer<PollsBloc, PollsState>(
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
              case PollsStatus.initial:
              case PollsStatus.loading:
                return const AppLoader();
              case PollsStatus.failure when state.polls.isEmpty:
                return ErrorView(
                  message: state.errorMessage ?? 'Could not load polls.',
                  onRetry: () =>
                      context.read<PollsBloc>().add(const PollsLoadRequested()),
                );
              case PollsStatus.success:
              case PollsStatus.failure:
                if (state.polls.isEmpty) {
                  return const EmptyState(
                    icon: LucideIcons.barChart3,
                    title: 'No active polls',
                    subtitle: 'New polls will appear here.',
                  );
                }
                final bloc = context.read<PollsBloc>();
                return RefreshIndicator(
                  onRefresh: () async =>
                      bloc.add(const PollsRefreshRequested()),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: state.polls.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final poll = state.polls[index];
                      return FadeSlideIn(
                        index: index,
                        child: PollCard(
                          poll: poll,
                          votedIndex: state.votedIndexFor(poll.id),
                          onVote: (i) => bloc.add(
                            PollVoteCast(pollId: poll.id, optionIndex: i),
                          ),
                        ),
                      );
                    },
                  ),
                );
            }
          },
        ),
          );
        },
      ),
    );
  }

  Future<void> _onCreate(BuildContext context) async {
    final bloc = context.read<PollsBloc>();
    final result = await CreatePollSheet.show(context);
    if (result != null) {
      bloc.add(PollCreated(question: result.question, options: result.options));
    }
  }
}
