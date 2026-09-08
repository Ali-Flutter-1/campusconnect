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
    super.replyToId,
    super.replyTo,
    super.editedAt,
    super.deletedAt,
    super.reactions,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // `reply_to` is the embedded parent row when the query asked for the join;
    // realtime payloads carry only the foreign key.
    final parent = json['reply_to'];
    return ChatMessageModel(
      id: json['id'].toString(),
      senderId: json['sender_id'] as String?,
      senderName: (json['sender_name'] as String?) ?? 'Anonymous',
      content: (json['content'] as String?) ?? '',
      room: (json['room'] as String?) ?? 'global',
      createdAt: _time(json['created_at']) ?? DateTime.now(),
      replyToId: json['reply_to_id']?.toString(),
      replyTo: parent is Map<String, dynamic>
          ? ReplyPreview(
              id: parent['id'].toString(),
              senderName: (parent['sender_name'] as String?) ?? 'Anonymous',
              content: (parent['content'] as String?) ?? '',
              deleted: parent['deleted_at'] != null,
            )
          : null,
      editedAt: _time(json['edited_at']),
      deletedAt: _time(json['deleted_at']),
    );
  }

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  /// Columns to request, including the embedded parent for reply previews.
  static const String columns =
      '*, reply_to:reply_to_id (id, sender_name, content, deleted_at)';
}
