import '../../domain/entities/chat_message.dart';

/// Data-layer [ChatMessage] with Supabase (de)serialization.
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.content,
    required super.room,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'].toString(),
      senderId: json['sender_id'] as String?,
      senderName: (json['sender_name'] as String?) ?? 'Anonymous',
      content: (json['content'] as String?) ?? '',
      room: (json['room'] as String?) ?? 'global',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}
