import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/chat_change.dart';
import '../models/chat_message_model.dart';

abstract interface class ChatRemoteDataSource {
  String? get currentUserId;

  /// A page of messages for [room], newest first, with their reactions already
  /// merged in. Pass [before] to load the page of messages older than that
  /// timestamp (cursor pagination).
  Future<List<ChatMessageModel>> getMessages(
    String room, {
    int limit,
    DateTime? before,
  });

  /// Live inserts, edits/soft-deletes and hard deletes in [room].
  Stream<ChatChange> watchMessages(String room);

  /// Live reaction add/remove in [room].
  Stream<ReactionChange> watchReactions(String room);

  Future<void> sendMessage({
    required String room,
    required String content,
    String? replyToId,
  });
  Future<void> editMessage({required String id, required String content});
  Future<void> deleteMessage(String id);
  Future<void> addReaction({required String messageId, required String emoji});
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<ChatMessageModel>> getMessages(
    String room, {
    int limit = 20,
    DateTime? before,
  }) async {
    try {
      var query =
          _client.from('chat_messages').select(ChatMessageModel.columns).eq('room', room);
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }
      // Newest first so cursor pagination ("older than X") is a simple limit.
      final rows =
          await query.order('created_at', ascending: false).limit(limit);
      final messages = rows.map(ChatMessageModel.fromJson).toList();
      if (messages.isEmpty) return messages;

      // One extra round trip for the page's reactions beats a per-message query.
      final reactions = await _reactionsFor(
        [for (final m in messages) m.id],
      );
      return [
        for (final m in messages)
          reactions.containsKey(m.id)
              ? ChatMessageModel(
                  id: m.id,
                  senderId: m.senderId,
                  senderName: m.senderName,
                  content: m.content,
                  room: m.room,
                  createdAt: m.createdAt,
                  replyToId: m.replyToId,
                  replyTo: m.replyTo,
                  editedAt: m.editedAt,
                  deletedAt: m.deletedAt,
                  reactions: reactions[m.id]!,
                )
              : m,
      ];
    } catch (_) {
      throw const ServerException();
    }
  }

  /// message id -> (emoji -> user ids).
  Future<Map<String, Map<String, List<String>>>> _reactionsFor(
    List<String> messageIds,
  ) async {
    final rows = await _client
        .from('chat_reactions')
        .select('message_id, user_id, emoji')
        .inFilter('message_id', messageIds);
    final result = <String, Map<String, List<String>>>{};
    for (final row in rows) {
      final byEmoji = result.putIfAbsent(
        row['message_id'].toString(),
        () => <String, List<String>>{},
      );
      byEmoji
          .putIfAbsent(row['emoji'] as String, () => <String>[])
          .add(row['user_id'].toString());
    }
    return result;
  }

  @override
  Stream<ChatChange> watchMessages(String room) {
    return _channelStream<ChatChange>(
      name: 'public:chat_messages:$room',
      table: 'chat_messages',
      room: room,
      onInsert: (row) => ChatChange.insert(ChatMessageModel.fromJson(row)),
      onUpdate: (row) => ChatChange.update(ChatMessageModel.fromJson(row)),
      onDelete: (row) => row['id'] == null
          ? null
          : ChatChange.delete(row['id'].toString()),
    );
  }

  @override
  Stream<ReactionChange> watchReactions(String room) {
    ReactionChange? map(Map<String, dynamic> row, {required bool added}) {
      final messageId = row['message_id'];
      final userId = row['user_id'];
      final emoji = row['emoji'];
      if (messageId == null || userId == null || emoji == null) return null;
      return ReactionChange(
        messageId: messageId.toString(),
        userId: userId.toString(),
        emoji: emoji as String,
        added: added,
      );
    }

    return _channelStream<ReactionChange>(
      name: 'public:chat_reactions:$room',
      table: 'chat_reactions',
      room: room,
      onInsert: (row) => map(row, added: true),
      onDelete: (row) => map(row, added: false),
    );
  }

  /// Subscribes to `public.[table]` filtered to [room] and maps each postgres
  /// change through the handler for its event, skipping ones that map to null
  /// (a DELETE payload without a replica identity, say).
  Stream<T> _channelStream<T>({
    required String name,
    required String table,
    required String room,
    T? Function(Map<String, dynamic> row)? onInsert,
    T? Function(Map<String, dynamic> row)? onUpdate,
    T? Function(Map<String, dynamic> row)? onDelete,
  }) {
    late final RealtimeChannel channel;
    late final StreamController<T> controller;

    controller = StreamController<T>(
      onListen: () {
        channel = _client.channel(name);
        final filter = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room',
          value: room,
        );
        void listen(
          PostgresChangeEvent event,
          T? Function(Map<String, dynamic>) handler,
          Map<String, dynamic> Function(PostgresChangePayload) pick,
        ) {
          channel.onPostgresChanges(
            event: event,
            schema: 'public',
            table: table,
            filter: filter,
            callback: (payload) {
              final mapped = handler(pick(payload));
              if (mapped != null) controller.add(mapped);
            },
          );
        }

        if (onInsert != null) {
          listen(PostgresChangeEvent.insert, onInsert, (p) => p.newRecord);
        }
        if (onUpdate != null) {
          listen(PostgresChangeEvent.update, onUpdate, (p) => p.newRecord);
        }
        if (onDelete != null) {
          listen(PostgresChangeEvent.delete, onDelete, (p) => p.oldRecord);
        }
        channel.subscribe();
      },
      onCancel: () => _client.removeChannel(channel),
    );

    return controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String room,
    required String content,
    String? replyToId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException();
    try {
      // sender_name is derived server-side by trg_chat_sender_name.
      await _client.from('chat_messages').insert({
        'sender_id': user.id,
        'content': content,
        'room': room,
        'reply_to_id': ?replyToId,
      });
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> editMessage({
    required String id,
    required String content,
  }) async {
    if (_client.auth.currentUser == null) throw const AuthException();
    try {
      await _client
          .from('chat_messages')
          .update({'content': content}).eq('id', id);
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> deleteMessage(String id) async {
    if (_client.auth.currentUser == null) throw const AuthException();
    try {
      // Soft delete: the row stays so replies keep their anchor.
      await _client.from('chat_messages').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException();
    try {
      await _client.from('chat_reactions').upsert(
        {'message_id': messageId, 'user_id': user.id, 'emoji': emoji},
        onConflict: 'message_id,user_id,emoji',
      );
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException();
    try {
      await _client
          .from('chat_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', user.id)
          .eq('emoji', emoji);
    } catch (_) {
      throw const ServerException();
    }
  }
}
