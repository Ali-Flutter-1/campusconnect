import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/poll.dart';

/// Contract for reading polls, the user's votes, and casting a vote.
abstract interface class PollRepository {
  Future<Either<Failure, List<Poll>>> getPolls({int? limit});

  /// Map of poll id → the option index the user voted for (empty when signed
  /// out or no votes).
  Future<Either<Failure, Map<String, int>>> getUserVotes();

  /// Casts a vote. Returns the failure 'already voted' path as an [AuthFailure]
  /// / [ServerFailure] message when the server rejects it.
  Future<Either<Failure, Unit>> vote({
    required String pollId,
    required int optionIndex,
  });

  /// Admin-only: creates a poll from a question and a list of option labels.
  Future<Either<Failure, Poll>> createPoll({
    required String question,
    required List<String> options,
  });
}
