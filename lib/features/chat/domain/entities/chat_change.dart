import 'chat_message.dart';

enum ChatChangeKind { insert, update, delete }

/// One realtime row change on `chat_messages`. Inserts and updates carry the
/// new row; deletes carry only the id (the row is gone).
class ChatChange {
  const ChatChange.insert(ChatMessage this.message)
      : kind = ChatChangeKind.insert,
        id = null;
  const ChatChange.update(ChatMessage this.message)
      : kind = ChatChangeKind.update,
        id = null;
  const ChatChange.delete(String this.id)
      : kind = ChatChangeKind.delete,
        message = null;

  final ChatChangeKind kind;
  final ChatMessage? message;
  final String? id;

  String get messageId => message?.id ?? id!;
}

/// One realtime row change on `chat_reactions`: a user added or removed [emoji]
/// on [messageId].
class ReactionChange {
  const ReactionChange({
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.added,
  });

  final String messageId;
  final String userId;
  final String emoji;
  final bool added;
}
