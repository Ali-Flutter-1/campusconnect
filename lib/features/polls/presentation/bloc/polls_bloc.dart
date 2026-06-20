import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/poll.dart';
import '../../domain/usecases/poll_usecases.dart';

part 'polls_event.dart';
part 'polls_state.dart';

/// Drives the Polls screen: load polls + the user's votes, and cast votes with
/// an optimistic update (reverted if the server rejects, e.g. already voted).
class PollsBloc extends Bloc<PollsEvent, PollsState> {
  PollsBloc({
    required GetPolls getPolls,
    required GetUserVotes getUserVotes,
    required CastVote castVote,
  })  : _getPolls = getPolls,
        _getUserVotes = getUserVotes,
        _castVote = castVote,
        super(const PollsState()) {
    on<PollsLoadRequested>(_onLoad);
    on<PollsRefreshRequested>(_onRefresh);
    on<PollVoteCast>(_onVote);
  }

  final GetPolls _getPolls;
  final GetUserVotes _getUserVotes;
  final CastVote _castVote;

  Future<void> _onLoad(PollsLoadRequested event, Emitter<PollsState> emit) async {
    emit(state.copyWith(status: PollsStatus.loading, clearError: true));
    await _load(emit);
  }

  Future<void> _onRefresh(
    PollsRefreshRequested event,
    Emitter<PollsState> emit,
  ) =>
      _load(emit);

  Future<void> _load(Emitter<PollsState> emit) async {
    final result = await _getPolls(const GetPollsParams());
    await result.fold(
      (failure) async => emit(state.copyWith(
        status: PollsStatus.failure,
        errorMessage: failure.message,
      )),
      (polls) async {
        final votes = await _getUserVotes(const NoParams());
        emit(state.copyWith(
          status: PollsStatus.success,
          polls: polls,
          votes: votes.getOrElse(() => const {}),
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onVote(PollVoteCast event, Emitter<PollsState> emit) async {
    if (state.votes.containsKey(event.pollId)) return; // already voted
    final previous = state;

    // Optimistic: record the vote and bump the option + total.
    final votes = {...state.votes, event.pollId: event.optionIndex};
    final polls = state.polls.map((p) {
      if (p.id != event.pollId) return p;
      final options = [
        for (var i = 0; i < p.options.length; i++)
          i == event.optionIndex
              ? p.options[i].copyWith(count: p.options[i].count + 1)
              : p.options[i],
      ];
      return Poll(
        id: p.id,
        question: p.question,
        options: options,
        totalVotes: p.totalVotes + 1,
        createdAt: p.createdAt,
        expiresAt: p.expiresAt,
      );
    }).toList();
    emit(state.copyWith(votes: votes, polls: polls));

    final result = await _castVote(
      VoteParams(pollId: event.pollId, optionIndex: event.optionIndex),
    );
    result.fold(
      (failure) => emit(previous.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }
}
