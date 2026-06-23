import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/filter_pill.dart';
import '../../../../injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/event.dart';
import '../bloc/events_bloc.dart';
import '../widgets/create_event_sheet.dart';
import '../widgets/event_card.dart';

/// Events screen. Students browse + RSVP and filter by category; admins also see
/// a "+" to schedule events and a delete action per card.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  static const _filters = ['all', 'academic', 'social', 'sports'];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EventsBloc>(
      create: (_) => getIt<EventsBloc>()..add(const EventsLoadRequested()),
      child: const _EventsView(),
    );
  }
}

class _EventsView extends StatelessWidget {
  const _EventsView();

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final isAdmin = context.select<AuthBloc, bool>((b) => b.state.isAdmin);

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'fab_events',
              onPressed: () => _onCreate(context),
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<EventsBloc, EventsState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Events',
                        style: AppTypography.inter(
                          size: AppTypography.xxxl,
                          weight: AppTypography.bold,
                          color: surfaces.primaryText,
                        ),
                      ),
                      Text(
                        'Discover campus activities',
                        style: AppTypography.inter(
                          size: AppTypography.base,
                          color: surfaces.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                _FilterBar(active: state.filter),
                Expanded(child: _Body(state: state, isAdmin: isAdmin)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _onCreate(BuildContext context) async {
    final bloc = context.read<EventsBloc>();
    final result = await CreateEventSheet.show(context);
    if (result != null) {
      bloc.add(EventCreated(
        title: result.title,
        description: result.description,
        date: result.date,
        time: result.time,
        location: result.location,
        category: result.category,
        imageBytes: result.image?.bytes,
        imageExt: result.image?.ext,
      ));
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.active});

  final String active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: EventsPage._filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final f = EventsPage._filters[index];
          return FilterPill(
            label: '${f[0].toUpperCase()}${f.substring(1)}',
            selected: active == f,
            onTap: () => context.read<EventsBloc>().add(EventsFilterChanged(f)),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.isAdmin});

  final EventsState state;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case EventsStatus.initial:
      case EventsStatus.loading:
        return const AppLoader();
      case EventsStatus.failure when state.events.isEmpty:
        return ErrorView(
          message: state.errorMessage ?? 'Could not load events.',
          onRetry: () =>
              context.read<EventsBloc>().add(const EventsLoadRequested()),
        );
      case EventsStatus.success:
      case EventsStatus.failure:
        if (state.events.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.calendar,
            title: 'No events',
            subtitle: 'Nothing scheduled in this category yet.',
          );
        }
        final bloc = context.read<EventsBloc>();
        return RefreshIndicator(
          onRefresh: () async => bloc.add(const EventsRefreshRequested()),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                bloc.add(const EventsLoadMoreRequested());
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
              itemCount: state.events.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index >= state.events.length) {
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
                final e = state.events[index];
                return FadeSlideIn(
                  index: index < AppConstants.pageSize ? index : 0,
                  child: EventCard(
                    event: e,
                    onEdit: isAdmin ? () => _onEdit(context, bloc, e) : null,
                    onDelete:
                        isAdmin ? () => bloc.add(EventDeleted(e.id)) : null,
                  ),
                );
              },
            ),
          ),
        );
    }
  }

  Future<void> _onEdit(BuildContext context, EventsBloc bloc, Event e) async {
    final result = await CreateEventSheet.show(context, initial: e);
    if (result != null) {
      bloc.add(EventUpdated(
        id: e.id,
        title: result.title,
        description: result.description,
        date: result.date,
        time: result.time,
        location: result.location,
        category: result.category,
      ));
    }
  }
}
