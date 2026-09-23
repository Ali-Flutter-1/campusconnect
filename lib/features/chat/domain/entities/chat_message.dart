import 'package:equatable/equatable.dart';

/// The message a reply points at, as much of it as we need to render the quoted
/// strip above the bubble.
class ReplyPreview extends Equatable {
  const ReplyPreview({
    required this.id,
    required this.senderName,
    required this.content,
    this.deleted = false,
  });

  final String id;
  final String senderName;
  final String content;
  final bool deleted;

  @override
  List<Object?> get props => [id, senderName, content, deleted];
}

/// A single chat message in a room. Mirrors the `chat_messages` table, plus two
/// client-only flags for messages that were composed offline:
/// - [pending]: queued in the outbox, not yet confirmed by the server.
/// - [failed]: the queued send was permanently rejected.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.room,
    required this.createdAt,
    this.replyToId,
    this.replyTo,
    this.editedAt,
    this.deletedAt,
    this.reactions = const {},
    this.pending = false,
    this.failed = false,
    this.local = false,
  });

  final String id;
  final String? senderId;
  final String senderName;
  final String content;
  final String room;
  final DateTime createdAt;

  /// The message this one replies to, and its preview when we could resolve it.
  final String? replyToId;
  final ReplyPreview? replyTo;

  /// Set once the author edited the message; null while it is untouched.
  final DateTime? editedAt;

  /// Set when the author removed the message (soft delete — the row stays so
  /// replies pointing at it keep their anchor).
  final DateTime? deletedAt;

  /// emoji -> ids of the users who reacted with it.
  final Map<String, List<String>> reactions;

  /// Queued in the outbox, not yet confirmed by the server (shows a clock).
  final bool pending;

  /// The queued send was permanently rejected (shows tap-to-retry).
  final bool failed;

  /// This row was built on the device and has no server id yet, so it must be
  /// replaced when its realtime echo arrives. It stays true after [pending]
  /// clears: delivery is confirmed by the outbox, which can land before — or
  /// instead of — the echo.
  final bool local;

  bool get isEdited => editedAt != null;
  bool get isDeleted => deletedAt != null;

  /// Whether [userId] already reacted to this message with [emoji].
  bool hasReaction(String emoji, String? userId) =>
      userId != null && (reactions[emoji]?.contains(userId) ?? false);

  ChatMessage copyWith({
    String? content,
    ReplyPreview? replyTo,
    DateTime? editedAt,
    DateTime? deletedAt,
    Map<String, List<String>>? reactions,
    bool? pending,
    bool? failed,
    bool? local,
  }) =>
      ChatMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        content: content ?? this.content,
        room: room,
        createdAt: createdAt,
        replyToId: replyToId,
        replyTo: replyTo ?? this.replyTo,
        editedAt: editedAt ?? this.editedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        reactions: reactions ?? this.reactions,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        local: local ?? this.local,
      );

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        content,
        room,
        createdAt,
        replyToId,
        replyTo,
        editedAt,
        deletedAt,
        reactions,
        pending,
        failed,
        local,
      ];
}
