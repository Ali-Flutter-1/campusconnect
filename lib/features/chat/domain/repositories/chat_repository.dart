import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_change.dart';
import '../entities/chat_message.dart';

/// Contract for the realtime chat. Implemented in the data layer.
abstract interface class ChatRepository {
  /// The id of the signed-in user (for "is this my message?" checks).
  String? get currentUserId;

  /// Loads a page of messages in [room], newest first. [before] loads the page
  /// older than that timestamp (cursor pagination).
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String room, {
    int limit,
    DateTime? before,
  });

  /// A live stream of message inserts/edits/deletes in [room].
  Stream<ChatChange> watchMessages(String room);

  /// A live stream of reaction add/remove in [room].
  Stream<ReactionChange> watchReactions(String room);

  /// Sends a message to [room] as the current user, optionally as a reply to
  /// [replyToId].
  Future<Either<Failure, Unit>> sendMessage({
    required String room,
    required String content,
    String? replyToId,
  });

  /// Rewrites the content of the caller's own message.
  Future<Either<Failure, Unit>> editMessage({
    required String id,
    required String content,
  });

  /// Soft-deletes the caller's own message.
  Future<Either<Failure, Unit>> deleteMessage(String id);

  /// Adds or removes the current user's [emoji] on [messageId].
  Future<Either<Failure, Unit>> toggleReaction({
    required String messageId,
    required String emoji,
    required bool add,
  });
}
