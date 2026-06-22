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

/// Admin-only: create a poll.
class PollCreated extends PollsEvent {
  const PollCreated({required this.question, required this.options});
  final String question;
  final List<String> options;

  @override
  List<Object?> get props => [question, options];
}
