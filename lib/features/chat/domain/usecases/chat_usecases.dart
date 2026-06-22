import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
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
  const SendMessageParams({required this.room, required this.content});
  final String room;
  final String content;

  @override
  List<Object?> get props => [room, content];
}

/// Sends a message.
class SendMessage implements UseCase<Unit, SendMessageParams> {
  const SendMessage(this._repository);

  final ChatRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SendMessageParams params) =>
      _repository.sendMessage(room: params.room, content: params.content);
}

/// Live stream of new messages in a room (not a Future, so it does not use the
/// [UseCase] interface).
class WatchMessages {
  const WatchMessages(this._repository);

  final ChatRepository _repository;

  Stream<ChatMessage> call(String room) => _repository.watchMessages(room);
}

/// The signed-in user's id, for "is this my message?" alignment.
class GetCurrentUserId {
  const GetCurrentUserId(this._repository);

  final ChatRepository _repository;

  String? call() => _repository.currentUserId;
}
