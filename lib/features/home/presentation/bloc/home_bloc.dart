import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../announcements/domain/entities/announcement.dart';
import '../../../announcements/domain/usecases/get_announcements.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/domain/usecases/get_events.dart';
import '../../../polls/domain/entities/poll.dart';
import '../../../polls/domain/usecases/poll_usecases.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Aggregates the student Home feed: the latest announcements, upcoming events
/// and active polls. Read-only — actions live on each feature's own screen.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetAnnouncements getAnnouncements,
    required GetEvents getEvents,
    required GetPolls getPolls,
  })  : _getAnnouncements = getAnnouncements,
        _getEvents = getEvents,
        _getPolls = getPolls,
        super(const HomeState()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
  }

  final GetAnnouncements _getAnnouncements;
  final GetEvents _getEvents;
  final GetPolls _getPolls;

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    if (event is HomeLoadRequested) {
      emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    }

    final announcements = await _getAnnouncements(const NoParams());
    final events = await _getEvents('all');
    final polls = await _getPolls(const GetPollsParams(limit: 2));

    // Home is best-effort: if any one section fails we still render the rest.
    final hadError = announcements.isLeft() || events.isLeft() || polls.isLeft();

    emit(state.copyWith(
      status: HomeStatus.success,
      announcements: announcements
          .getOrElse(() => const [])
          .take(3)
          .toList(),
      events: events.getOrElse(() => const []).take(3).toList(),
      polls: polls.getOrElse(() => const []),
      errorMessage: hadError ? 'Some sections failed to load.' : null,
      clearError: !hadError,
    ));
  }
}
