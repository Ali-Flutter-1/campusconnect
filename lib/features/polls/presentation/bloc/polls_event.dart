part of 'polls_bloc.dart';

sealed class PollsEvent extends Equatable {
  const PollsEvent();

  @override
  List<Object?> get props => [];
}

class PollsLoadRequested extends PollsEvent {
  const PollsLoadRequested();
}

class PollsRefreshRequested extends PollsEvent {
  const PollsRefreshRequested();
}

class PollVoteCast extends PollsEvent {
  const PollVoteCast({required this.pollId, required this.optionIndex});
  final String pollId;
  final int optionIndex;

  @override
  List<Object?> get props => [pollId, optionIndex];
}
