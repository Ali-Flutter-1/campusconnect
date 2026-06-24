import '../../../../core/error/failures.dart';
import '../../../../core/sync/outbox_handler.dart';
import '../../domain/repositories/poll_repository.dart';

/// Flushes a queued poll vote to Supabase. Registered with the SyncService.
class PollVoteHandler implements OutboxHandler {
  const PollVoteHandler(this._repository);

  final PollRepository _repository;

  static const String kType = 'poll.vote';
  static const String kPollId = 'poll_id';
  static const String kOptionIndex = 'option_index';

  @override
  String get type => kType;

  @override
  Future<SyncOutcome> handle(Map<String, dynamic> payload) async {
    final result = await _repository.vote(
      pollId: payload[kPollId] as String,
      optionIndex: (payload[kOptionIndex] as num).toInt(),
    );
    return result.fold(
      (failure) =>
          failure is NetworkFailure ? SyncOutcome.retry : SyncOutcome.fail,
      (_) => SyncOutcome.success,
    );
  }
}
