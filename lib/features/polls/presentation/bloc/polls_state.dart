part of 'polls_bloc.dart';

enum PollsStatus { initial, loading, success, failure }

class PollsState extends Equatable {
  const PollsState({
    this.status = PollsStatus.initial,
    this.polls = const [],
    this.votes = const {},
    this.errorMessage,
  });

  final PollsStatus status;
  final List<Poll> polls;

  /// poll id → option index the user voted for.
  final Map<String, int> votes;
  final String? errorMessage;

  int? votedIndexFor(String pollId) => votes[pollId];

  PollsState copyWith({
    PollsStatus? status,
    List<Poll>? polls,
    Map<String, int>? votes,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PollsState(
      status: status ?? this.status,
      polls: polls ?? this.polls,
      votes: votes ?? this.votes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, polls, votes, errorMessage];
}
