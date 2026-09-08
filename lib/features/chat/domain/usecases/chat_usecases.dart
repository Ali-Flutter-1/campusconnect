import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_change.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetMessagesParams extends Equatable {
  const GetMessagesParams({
    required this.room,
    this.limit = AppConstants.pageSize,
    this.before,
  });

  final String room;
  final int limit;
  final DateTime? before;

  @override
  List<Object?> get props => [room, limit, before];
}

/// Loads a page of messages for a room (newest first; cursor via [before]).
class GetMessages implements UseCase<List<ChatMessage>, GetMessagesParams> {
  const GetMessages(this._repository);

  final ChatRepository _repository;

  @override
  Future<Either<Failure, List<ChatMessage>>> call(GetMessagesParams params) =>
      _repository.getMessages(
        params.room,
        limit: params.limit,
        before: params.before,
      );
}

class SendMessageParams extends Equatable {
  const SendMessageParams({
    required this.room,
    required this.content,
    this.replyToId,
  });

  final String room;
  final String content;
  final String? replyToId;

  @override
  List<Object?> get props => [room, content, replyToId];
}

/// Sends a message, optionally as a reply.
class SendMessage implements UseCase<Unit, SendMessageParams> {
  const SendMessage(this._repository);

  final ChatRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SendMessageParams params) =>
      _repository.sendMessage(
        room: params.room,
        content: params.content,
        replyToId: params.replyToId,
      );
}

class EditMessageParams extends Equatable {
  const EditMessageParams({required this.id, required this.content});
  final String id;
  final String content;

  @override
  List<Object?> get props => [id, content];
}

/// Rewrites one of the user's own messages.
class EditMessage implements UseCase<Unit, EditMessageParams> {
  const EditMessage(this._repository);

  final ChatRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(EditMessageParams params) =>
      _repository.editMessage(id: params.id, content: params.content);
}

/// Soft-deletes one of the user's own messages.
class DeleteMessage implements UseCase<Unit, String> {
  const DeleteMessage(this._repository);

  final ChatRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String id) =>
      _repository.deleteMessage(id);
}

class ToggleReactionParams extends Equatable {
  const ToggleReactionParams({
    required this.messageId,
    required this.emoji,
    required this.add,
  });

  final String messageId;
  final String emoji;
  final bool add;

  @override
  List<Object?> get props => [messageId, emoji, add];
}

/// Adds or removes the current user's emoji reaction on a message.
class ToggleReaction implements UseCase<Unit, ToggleReactionParams> {
  const ToggleReaction(this._repository);

  final ChatRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ToggleReactionParams params) =>
      _repository.toggleReaction(
        messageId: params.messageId,
        emoji: params.emoji,
        add: params.add,
      );
}

/// Live stream of message changes in a room (not a Future, so it does not use
/// the [UseCase] interface).
class WatchMessages {
  const WatchMessages(this._repository);

  final ChatRepository _repository;

  Stream<ChatChange> call(String room) => _repository.watchMessages(room);
}

/// Live stream of reaction changes in a room.
class WatchReactions {
  const WatchReactions(this._repository);

  final ChatRepository _repository;

  Stream<ReactionChange> call(String room) => _repository.watchReactions(room);
}

/// The signed-in user's id, for "is this my message?" alignment.
class GetCurrentUserId {
  const GetCurrentUserId(this._repository);

  final ChatRepository _repository;

  String? call() => _repository.currentUserId;
}
