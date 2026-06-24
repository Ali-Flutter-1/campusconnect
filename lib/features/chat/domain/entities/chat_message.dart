import 'package:equatable/equatable.dart';

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
    this.pending = false,
    this.failed = false,
  });

  final String id;
  final String? senderId;
  final String senderName;
  final String content;
  final String room;
  final DateTime createdAt;
  final bool pending;
  final bool failed;

  ChatMessage copyWith({bool? pending, bool? failed}) => ChatMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        content: content,
        room: room,
        createdAt: createdAt,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );

  @override
  List<Object?> get props =>
      [id, senderId, senderName, content, room, createdAt, pending, failed];
}
