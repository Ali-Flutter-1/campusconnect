import 'package:equatable/equatable.dart';

/// A single chat message in a room. Mirrors the `chat_messages` table.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.room,
    required this.createdAt,
  });

  final String id;
  final String? senderId;
  final String senderName;
  final String content;
  final String room;
  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [id, senderId, senderName, content, room, createdAt];
}
