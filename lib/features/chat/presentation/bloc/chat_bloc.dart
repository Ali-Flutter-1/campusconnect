import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/sync/outbox_handler.dart';
import '../../../../core/sync/sync_service.dart';
import '../../data/sync/chat_send_handler.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/chat_usecases.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Drives the realtime chat. Loads history, streams new messages via Supabase
/// Realtime, and **sends through the offline outbox**: a message is shown
/// optimistically (pending), queued, and flushed in order when online — the
/// realtime echo then confirms it. Pending sends survive app restarts.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required GetMessages getMessages,
    required WatchMessages watchMessages,
    required GetCurrentUserId getCurrentUserId,
    required SyncService syncService,
  })  : _getMessages = getMessages,
        _watchMessages = watchMessages,
        _getCurrentUserId = getCurrentUserId,
        _sync = syncService,
        super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatOlderRequested>(_onOlderRequested);
    on<ChatSendRequested>(_onSendRequested);
    on<ChatRetryRequested>(_onRetryRequested);
    on<_ChatSyncResult>(_onSyncResult);
  }

  final GetMessages _getMessages;
  final WatchMessages _watchMessages;
  final GetCurrentUserId _getCurrentUserId;
  final SyncService _sync;

  StreamSubscription<ChatMessage>? _sub;
  StreamSubscription<SyncResult>? _syncSub;
  String _room = 'global';

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    _room = event.room;
    emit(state.copyWith(
      status: ChatStatus.loading,
      currentUserId: _getCurrentUserId(),
    ));

    final result = await _getMessages(GetMessagesParams(room: _room));
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChatStatus.failure,
        errorMessage: failure.message,
      )),
      // Stored newest-first (index 0 = newest); rendered in a reversed list.
      // Prepend any still-queued offline messages so they survive a restart.
      (messages) => emit(state.copyWith(
        status: ChatStatus.success,
        messages: [..._pendingMessages(), ...messages],
        hasReachedMax: messages.length < AppConstants.pageSize,
        clearError: true,
      )),
    );

    await _sub?.cancel();
    _sub = _watchMessages(_room).listen(
      (message) => add(ChatMessageReceived(message)),
    );
    await _syncSub?.cancel();
    _syncSub = _sync.results
        .where((r) => r.type == ChatSendHandler.kType)
        .listen((r) => add(_ChatSyncResult(r)));
  }

  /// Rebuilds optimistic [ChatMessage]s from any queued (unsent) chat writes for
  /// this room.
  List<ChatMessage> _pendingMessages() {
    final uid = _getCurrentUserId();
    final queued = _sync
        .pending(ChatSendHandler.kType)
        .where((e) => e.payload[ChatSendHandler.kRoom] == _room)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
    return [
      for (final e in queued)
        ChatMessage(
          id: e.id,
          senderId: uid,
          senderName: 'You',
          content: e.payload[ChatSendHandler.kContent] as String,
          room: _room,
          createdAt: e.createdAt,
          pending: true,
        ),
    ];
  }

  void _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    final incoming = event.message;
    final list = [...state.messages];

    // Reconcile: a realtime echo of my own message replaces its pending copy.
    if (incoming.senderId != null && incoming.senderId == state.currentUserId) {
      final i = list.indexWhere(
        (m) => m.pending && m.content == incoming.content,
      );
      if (i != -1) list.removeAt(i);
    }
    if (list.any((m) => m.id == incoming.id)) {
      emit(state.copyWith(messages: list));
      return;
    }
    emit(state.copyWith(messages: [incoming, ...list]));
  }

  Future<void> _onOlderRequested(
    ChatOlderRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state.hasReachedMax || state.isLoadingMore || state.messages.isEmpty) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getMessages(GetMessagesParams(
      room: _room,
      before: state.messages.last.createdAt,
    ));
    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (older) => emit(state.copyWith(
        // Older messages append to the end (top of the reversed list).
        messages: [...state.messages, ...older],
        isLoadingMore: false,
        hasReachedMax: older.length < AppConstants.pageSize,
      )),
    );
  }

  Future<void> _onSendRequested(
    ChatSendRequested event,
    Emitter<ChatState> emit,
  ) async {
    final content = event.content.trim();
    if (content.isEmpty) return;

    final clientId = '${DateTime.now().microsecondsSinceEpoch}';
    final pending = ChatMessage(
      id: clientId,
      senderId: state.currentUserId,
      senderName: 'You',
      content: content,
      room: _room,
      createdAt: DateTime.now(),
      pending: true,
    );
    emit(state.copyWith(messages: [pending, ...state.messages]));

    await _sync.enqueue(
      ChatSendHandler.kType,
      {ChatSendHandler.kRoom: _room, ChatSendHandler.kContent: content},
      id: clientId,
    );
  }

  Future<void> _onRetryRequested(
    ChatRetryRequested event,
    Emitter<ChatState> emit,
  ) async {
    final i = state.messages.indexWhere((m) => m.id == event.messageId);
    if (i == -1) return;
    final msg = state.messages[i];
    final list = [...state.messages]
      ..[i] = msg.copyWith(pending: true, failed: false);
    emit(state.copyWith(messages: list));
    await _sync.enqueue(
      ChatSendHandler.kType,
      {ChatSendHandler.kRoom: _room, ChatSendHandler.kContent: msg.content},
      id: msg.id,
    );
  }

  void _onSyncResult(_ChatSyncResult event, Emitter<ChatState> emit) {
    if (event.result.outcome != SyncOutcome.fail) return;
    // The realtime echo handles success; only mark permanent failures here.
    final list = state.messages
        .map((m) => m.id == event.result.id
            ? m.copyWith(pending: false, failed: true)
            : m)
        .toList();
    emit(state.copyWith(messages: list));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _syncSub?.cancel();
    return super.close();
  }
}
