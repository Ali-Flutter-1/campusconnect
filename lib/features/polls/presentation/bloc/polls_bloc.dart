import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/sync/outbox_handler.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/sync/poll_vote_handler.dart';
import '../../domain/entities/poll.dart';
import '../../domain/usecases/poll_usecases.dart';

part 'polls_event.dart';
part 'polls_state.dart';

/// Drives the Polls screen: load polls + the user's votes, create polls, and
/// cast votes **through the offline outbox** — the vote shows optimistically and
/// is queued, then flushed when online (reverted only if permanently rejected,
/// e.g. already voted).
class PollsBloc extends Bloc<PollsEvent, PollsState> {
  PollsBloc({
    required GetPolls getPolls,
    required GetUserVotes getUserVotes,
    required CreatePoll createPoll,
    required SyncService syncService,
  })  : _getPolls = getPolls,
        _getUserVotes = getUserVotes,
        _createPoll = createPoll,
        _sync = syncService,
        super(const PollsState()) {
    on<PollsLoadRequested>(_onLoad);
    on<PollsRefreshRequested>(_onRefresh);
    on<PollVoteCast>(_onVote);
    on<PollCreated>(_onCreated);
    on<_PollSyncResult>(_onSyncResult);

    _syncSub = _sync.results
        .where((r) => r.type == PollVoteHandler.kType)
        .listen((r) => add(_PollSyncResult(r)));
  }

  final GetPolls _getPolls;
  final GetUserVotes _getUserVotes;
  final CreatePoll _createPoll;
  final SyncService _sync;

  StreamSubscription<SyncResult>? _syncSub;

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
    // Bound the fetch — the Polls page renders the full list eagerly, so cap
    // it at the most recent 50 rather than loading every poll ever created.
    final result = await _getPolls(const GetPollsParams(limit: 50));
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

    // Optimistic: record the vote and bump the option + total.
    emit(_applyVote(event.pollId, event.optionIndex, 1));

    await _sync.enqueue(PollVoteHandler.kType, {
      PollVoteHandler.kPollId: event.pollId,
      PollVoteHandler.kOptionIndex: event.optionIndex,
    });
  }

  void _onSyncResult(_PollSyncResult event, Emitter<PollsState> emit) {
    if (event.result.outcome != SyncOutcome.fail) return;
    final pollId = event.result.payload[PollVoteHandler.kPollId] as String;
    final optionIndex =
        (event.result.payload[PollVoteHandler.kOptionIndex] as num).toInt();
    if (!state.votes.containsKey(pollId)) return;
    // Permanent rejection — undo the optimistic vote.
    emit(_applyVote(pollId, optionIndex, -1).copyWith(
      errorMessage: 'Your vote could not be saved.',
    ));
  }

  Future<void> _onCreated(PollCreated event, Emitter<PollsState> emit) async {
    final result = await _createPoll(
      CreatePollParams(question: event.question, options: event.options),
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (created) => emit(state.copyWith(polls: [created, ...state.polls])),
    );
  }

  /// Applies (delta = +1) or reverts (delta = -1) a vote for [pollId] on
  /// [optionIndex], adjusting the votes map, the option count and the total.
  PollsState _applyVote(String pollId, int optionIndex, int delta) {
    final votes = {...state.votes};
    if (delta > 0) {
      votes[pollId] = optionIndex;
    } else {
      votes.remove(pollId);
    }
    final polls = state.polls.map((p) {
      if (p.id != pollId) return p;
      final options = [
        for (var i = 0; i < p.options.length; i++)
          i == optionIndex
              ? p.options[i]
                  .copyWith(count: math.max(0, p.options[i].count + delta))
              : p.options[i],
      ];
      return Poll(
        id: p.id,
        question: p.question,
        options: options,
        totalVotes: math.max(0, p.totalVotes + delta),
        createdAt: p.createdAt,
        expiresAt: p.expiresAt,
      );
    }).toList();
    return state.copyWith(votes: votes, polls: polls);
  }

  @override
  Future<void> close() {
    _syncSub?.cancel();
    return super.close();
  }
}
