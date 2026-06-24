import '../../../../core/error/failures.dart';
import '../../../../core/sync/outbox_handler.dart';
import '../../domain/repositories/chat_repository.dart';

/// Flushes a queued chat message to Supabase. Registered with the SyncService.
class ChatSendHandler implements OutboxHandler {
  const ChatSendHandler(this._repository);

  final ChatRepository _repository;

  /// Outbox entry type + payload keys (shared with the ChatBloc).
  static const String kType = 'chat.send';
  static const String kRoom = 'room';
  static const String kContent = 'content';

  @override
  String get type => kType;

  @override
  Future<SyncOutcome> handle(Map<String, dynamic> payload) async {
    final result = await _repository.sendMessage(
      room: payload[kRoom] as String,
      content: payload[kContent] as String,
    );
    return result.fold(
      (failure) =>
          failure is NetworkFailure ? SyncOutcome.retry : SyncOutcome.fail,
      (_) => SyncOutcome.success,
    );
  }
}
