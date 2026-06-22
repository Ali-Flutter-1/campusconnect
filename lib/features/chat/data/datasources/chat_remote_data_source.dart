import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../models/chat_message_model.dart';

abstract interface class ChatRemoteDataSource {
  String? get currentUserId;

  /// A page of messages for [room], newest first. Pass [before] to load the
  /// page of messages older than that timestamp (cursor pagination).
  Future<List<ChatMessageModel>> getMessages(
    String room, {
    int limit,
    DateTime? before,
  });
  Stream<ChatMessageModel> watchMessages(String room);
  Future<void> sendMessage({required String room, required String content});
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
      var query = _client.from('chat_messages').select().eq('room', room);
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }
      // Newest first so cursor pagination ("older than X") is a simple limit.
      final rows =
          await query.order('created_at', ascending: false).limit(limit);
      return rows.map(ChatMessageModel.fromJson).toList();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<ChatMessageModel> watchMessages(String room) {
    late final RealtimeChannel channel;
    late final StreamController<ChatMessageModel> controller;

    controller = StreamController<ChatMessageModel>(
      onListen: () {
        channel = _client.channel('public:chat_messages:$room');
        channel
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'chat_messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'room',
                value: room,
              ),
              callback: (payload) {
                controller.add(ChatMessageModel.fromJson(payload.newRecord));
              },
            )
            .subscribe();
      },
      onCancel: () => _client.removeChannel(channel),
    );

    return controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String room,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException();
    try {
      final profile = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final name = (profile?['full_name'] as String?) ?? 'Anonymous';
      await _client.from('chat_messages').insert({
        'sender_id': user.id,
        'sender_name': name,
        'content': content,
        'room': room,
      });
    } catch (_) {
      throw const ServerException();
    }
  }
}
