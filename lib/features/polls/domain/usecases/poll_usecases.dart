import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/poll.dart';
import '../repositories/poll_repository.dart';

class GetPollsParams extends Equatable {
  const GetPollsParams({this.limit});
  final int? limit;

  @override
  List<Object?> get props => [limit];
}

class GetPolls implements UseCase<List<Poll>, GetPollsParams> {
  const GetPolls(this._repository);

  final PollRepository _repository;

  @override
  Future<Either<Failure, List<Poll>>> call(GetPollsParams params) =>
      _repository.getPolls(limit: params.limit);
}

class GetUserVotes implements UseCase<Map<String, int>, NoParams> {
  const GetUserVotes(this._repository);

  final PollRepository _repository;

  @override
  Future<Either<Failure, Map<String, int>>> call(NoParams params) =>
      _repository.getUserVotes();
}

class VoteParams extends Equatable {
  const VoteParams({required this.pollId, required this.optionIndex});
  final String pollId;
  final int optionIndex;

  @override
  List<Object?> get props => [pollId, optionIndex];
}

class CastVote implements UseCase<Unit, VoteParams> {
  const CastVote(this._repository);

  final PollRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(VoteParams params) => _repository.vote(
        pollId: params.pollId,
        optionIndex: params.optionIndex,
      );
}

class CreatePollParams extends Equatable {
  const CreatePollParams({required this.question, required this.options});
  final String question;
  final List<String> options;

  @override
  List<Object?> get props => [question, options];
}

/// Admin-only: creates a poll.
class CreatePoll implements UseCase<Poll, CreatePollParams> {
  const CreatePoll(this._repository);

  final PollRepository _repository;

  @override
  Future<Either<Failure, Poll>> call(CreatePollParams params) =>
      _repository.createPoll(question: params.question, options: params.options);
}
