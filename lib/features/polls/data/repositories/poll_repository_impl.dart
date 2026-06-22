import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/poll.dart';
import '../../domain/repositories/poll_repository.dart';
import '../datasources/poll_remote_data_source.dart';

class PollRepositoryImpl implements PollRepository {
  const PollRepositoryImpl(this._remote, this._networkInfo);

  final PollRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<Poll>>> getPolls({int? limit}) =>
      _guard(() => _remote.getPolls(limit: limit));

  @override
  Future<Either<Failure, Map<String, int>>> getUserVotes() =>
      _guard(_remote.getUserVotes);

  @override
  Future<Either<Failure, Unit>> vote({
    required String pollId,
    required int optionIndex,
  }) =>
      _guard(() async {
        await _remote.vote(pollId: pollId, optionIndex: optionIndex);
        return unit;
      });

  @override
  Future<Either<Failure, Poll>> createPoll({
    required String question,
    required List<String> options,
  }) =>
      _guard(() => _remote.createPoll(question: question, options: options));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
