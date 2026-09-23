import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/sync/outbox_handler.dart';
import '../../../../core/sync/sync_service.dart';
import '../../data/sync/chat_send_handler.dart';
import '../../domain/entities/chat_change.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/chat_usecases.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Drives the realtime chat. Loads history, streams changes via Supabase
/// Realtime, and **sends through the offline outbox**: a message is shown
/// optimistically (pending), queued, and flushed in order when online — the
/// realtime echo then confirms it. Pending sends survive app restarts.
///
/// Edits, deletes and reactions go straight to the server (they only make sense
/// against a row that already exists) and are applied optimistically, with the
/// realtime echo as the source of truth.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required GetMessages getMessages,
    required WatchMessages watchMessages,
    required WatchReactions watchReactions,
    required GetCurrentUserId getCurrentUserId,
    required EditMessage editMessage,
    required DeleteMessage deleteMessage,
    required ToggleReaction toggleReaction,
    required SyncService syncService,
  })  : _getMessages = getMessages,
        _watchMessages = watchMessages,
        _watchReactions = watchReactions,
        _getCurrentUserId = getCurrentUserId,
        _editMessage = editMessage,
        _deleteMessage = deleteMessage,
        _toggleReaction = toggleReaction,
        _sync = syncService,
        super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageChanged>(_onMessageChanged);
    on<ChatReactionChanged>(_onReactionChanged);
    on<ChatOlderRequested>(_onOlderRequested);
    on<ChatSendRequested>(_onSendRequested);
    on<ChatRetryRequested>(_onRetryRequested);
    on<ChatReplyStarted>(_onReplyStarted);
    on<ChatEditStarted>(_onEditStarted);
    on<ChatComposerCleared>(_onComposerCleared);
    on<ChatEditSubmitted>(_onEditSubmitted);
    on<ChatDeleteRequested>(_onDeleteRequested);
    on<ChatReactionToggled>(_onReactionToggled);
    on<_ChatSyncResult>(_onSyncResult);
  }

  final GetMessages _getMessages;
  final WatchMessages _watchMessages;
  final WatchReactions _watchReactions;
  final GetCurrentUserId _getCurrentUserId;
  final EditMessage _editMessage;
  final DeleteMessage _deleteMessage;
  final ToggleReaction _toggleReaction;
  final SyncService _sync;

  StreamSubscription<ChatChange>? _sub;
  StreamSubscription<ReactionChange>? _reactionSub;
  StreamSubscription<SyncResult>? _syncSub;
  String _room = 'global';

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    _room = event.room;
    emit(state.copyWith(
      status: ChatStatus.loading,
      currentUserId: _getCurrentUserId(),
    ));

    // Subscribe *before* loading history. Opening the channel afterwards left a
    // window in which inserts produced no echo — most often the user's own
    // first message, whose pending clock then never cleared.
    await _sub?.cancel();
    _sub = _watchMessages(_room).listen(
      (change) => add(ChatMessageChanged(change)),
    );
    await _reactionSub?.cancel();
    _reactionSub = _watchReactions(_room).listen(
      (change) => add(ChatReactionChanged(change)),
    );
    await _syncSub?.cancel();
    _syncSub = _sync.results
        .where((r) => r.type == ChatSendHandler.kType)
        .listen((r) => add(_ChatSyncResult(r)));

    // Show queued offline messages immediately so they survive a restart.
    emit(state.copyWith(messages: _pendingMessages()));

    final result = await _getMessages(GetMessagesParams(room: _room));
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChatStatus.failure,
        errorMessage: failure.message,
      )),
      // Stored newest-first (index 0 = newest); rendered in a reversed list.
      // Merge rather than replace: anything that arrived over the channel while
      // this page was loading is already in state and must not be dropped.
      (messages) {
        final known = {for (final m in state.messages) m.id};
        final merged = [
          ...state.messages,
          ...messages.where((m) => !known.contains(m.id)),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(state.copyWith(
          status: ChatStatus.success,
          messages: merged,
          // Based on the fetched page, not the merged list.
          hasReachedMax: messages.length < AppConstants.pageSize,
          clearError: true,
        ));
      },
    );
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
          replyToId: e.payload[ChatSendHandler.kReplyToId] as String?,
          pending: true,
          local: true,
        ),
    ];
  }

  void _onMessageChanged(ChatMessageChanged event, Emitter<ChatState> emit) {
    switch (event.change.kind) {
      case ChatChangeKind.insert:
        _onMessageReceived(event.change.message!, emit);
      case ChatChangeKind.update:
        _onMessageUpdated(event.change.message!, emit);
      case ChatChangeKind.delete:
        emit(state.copyWith(
          messages: state.messages
              .where((m) => m.id != event.change.id)
              .toList(),
        ));
    }
  }

  void _onMessageReceived(ChatMessage incoming, Emitter<ChatState> emit) {
    final list = [...state.messages];

    // Reconcile: a realtime echo of my own message replaces its pending copy.
    if (incoming.senderId != null && incoming.senderId == state.currentUserId) {
      final i = list.indexWhere(
        (m) => m.local && m.content == incoming.content,
      );
      if (i != -1) list.removeAt(i);
    }
    if (list.any((m) => m.id == incoming.id)) {
      emit(state.copyWith(messages: list));
      return;
    }
    // Realtime payloads carry only reply_to_id, so resolve the quote locally.
    emit(state.copyWith(
      messages: [_withResolvedReply(incoming, list), ...list],
    ));
  }

  /// Fills in [message]'s reply preview from an already-loaded message when the
  /// payload did not include the join.
  ChatMessage _withResolvedReply(ChatMessage message, List<ChatMessage> known) {
    if (message.replyToId == null || message.replyTo != null) return message;
    for (final m in known) {
      if (m.id == message.replyToId) {
        return message.copyWith(
          replyTo: ReplyPreview(
            id: m.id,
            senderName: m.senderName,
            content: m.content,
            deleted: m.isDeleted,
          ),
        );
      }
    }
    return message;
  }

  /// An edit or soft-delete arrived. Keep the client-side reply preview and
  /// reactions (the payload has neither) and refresh any quote of this message.
  void _onMessageUpdated(ChatMessage incoming, Emitter<ChatState> emit) {
    final i = state.messages.indexWhere((m) => m.id == incoming.id);
    if (i == -1) return;
    final existing = state.messages[i];
    final merged = incoming.copyWith(
      replyTo: existing.replyTo,
      reactions: existing.reactions,
    );
    final list = [...state.messages]..[i] = merged;
    emit(state.copyWith(messages: _refreshQuotesOf(merged, list)));
  }

  /// Rewrites the quoted strip on every message replying to [source].
  List<ChatMessage> _refreshQuotesOf(
    ChatMessage source,
    List<ChatMessage> list,
  ) {
    final preview = ReplyPreview(
      id: source.id,
      senderName: source.senderName,
      content: source.content,
      deleted: source.isDeleted,
    );
    return [
      for (final m in list)
        m.replyToId == source.id ? m.copyWith(replyTo: preview) : m,
    ];
  }

  void _onReactionChanged(ChatReactionChanged event, Emitter<ChatState> emit) {
    final change = event.change;
    final i = state.messages.indexWhere((m) => m.id == change.messageId);
    if (i == -1) return;
    final message = state.messages[i];
    final updated = _applyReaction(
      message,
      emoji: change.emoji,
      userId: change.userId,
      add: change.added,
    );
    if (updated.reactions == message.reactions) return;
    emit(state.copyWith(messages: [...state.messages]..[i] = updated));
  }

  /// Adds/removes [userId] in [message]'s reaction map, dropping an emoji once
  /// nobody holds it. Returns [message] unchanged when it is already correct.
  ChatMessage _applyReaction(
    ChatMessage message, {
    required String emoji,
    required String userId,
    required bool add,
  }) {
    final holders = message.reactions[emoji] ?? const <String>[];
    if (add == holders.contains(userId)) return message;

    final reactions = {
      for (final entry in message.reactions.entries) entry.key: [...entry.value],
    };
    if (add) {
      reactions.putIfAbsent(emoji, () => <String>[]).add(userId);
    } else {
      reactions[emoji]!.remove(userId);
      if (reactions[emoji]!.isEmpty) reactions.remove(emoji);
    }
    return message.copyWith(reactions: reactions);
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

    final replyTo = state.replyingTo;
    final clientId = '${DateTime.now().microsecondsSinceEpoch}';
    final pending = ChatMessage(
      id: clientId,
      senderId: state.currentUserId,
      senderName: 'You',
      content: content,
      room: _room,
      createdAt: DateTime.now(),
      replyToId: replyTo?.id,
      replyTo: replyTo == null
          ? null
          : ReplyPreview(
              id: replyTo.id,
              senderName: replyTo.senderName,
              content: replyTo.content,
              deleted: replyTo.isDeleted,
            ),
      pending: true,
      local: true,
    );
    emit(state.copyWith(
      messages: [pending, ...state.messages],
      clearComposerTarget: true,
    ));

    await _sync.enqueue(
      ChatSendHandler.kType,
      {
        ChatSendHandler.kRoom: _room,
        ChatSendHandler.kContent: content,
        // Only a server-side id can be an anchor; a reply to a still-pending
        // message posts as a plain message rather than dangling.
        if (replyTo != null && !replyTo.pending)
          ChatSendHandler.kReplyToId: replyTo.id,
      },
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
      {
        ChatSendHandler.kRoom: _room,
        ChatSendHandler.kContent: msg.content,
        if (msg.replyToId != null) ChatSendHandler.kReplyToId: msg.replyToId,
      },
      id: msg.id,
    );
  }

  void _onReplyStarted(ChatReplyStarted event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearComposerTarget: true));
    emit(state.copyWith(replyingTo: event.message));
  }

  void _onEditStarted(ChatEditStarted event, Emitter<ChatState> emit) {
    if (!state.isMine(event.message) || event.message.isDeleted) return;
    emit(state.copyWith(clearComposerTarget: true));
    emit(state.copyWith(editing: event.message));
  }

  void _onComposerCleared(ChatComposerCleared event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearComposerTarget: true));
  }

  Future<void> _onEditSubmitted(
    ChatEditSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    final target = state.editing;
    final content = event.content.trim();
    if (target == null) return;
    if (content.isEmpty || content == target.content) {
      emit(state.copyWith(clearComposerTarget: true));
      return;
    }

    final optimistic = target.copyWith(
      content: content,
      editedAt: DateTime.now(),
    );
    emit(state.copyWith(
      messages: _replace(optimistic),
      clearComposerTarget: true,
    ));

    final result = await _editMessage(
      EditMessageParams(id: target.id, content: content),
    );
    result.fold(
      // Roll back to the stored text; the realtime echo confirms a success.
      (failure) => emit(state.copyWith(
        messages: _replace(target),
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> _onDeleteRequested(
    ChatDeleteRequested event,
    Emitter<ChatState> emit,
  ) async {
    final i = state.messages.indexWhere((m) => m.id == event.messageId);
    if (i == -1) return;
    final target = state.messages[i];
    if (!state.isMine(target) || target.isDeleted) return;

    final deleted = target.copyWith(
      content: '',
      deletedAt: DateTime.now(),
      reactions: const {},
    );
    var list = _replace(deleted);
    list = _refreshQuotesOf(deleted, list);
    emit(state.copyWith(
      messages: list,
      // Do not leave the composer pointing at a message that is now gone.
      clearComposerTarget: state.replyingTo?.id == target.id ||
          state.editing?.id == target.id,
    ));

    final result = await _deleteMessage(target.id);
    result.fold(
      (failure) => emit(state.copyWith(
        messages: _refreshQuotesOf(target, _replace(target)),
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> _onReactionToggled(
    ChatReactionToggled event,
    Emitter<ChatState> emit,
  ) async {
    final userId = state.currentUserId;
    final i = state.messages.indexWhere((m) => m.id == event.messageId);
    if (userId == null || i == -1) return;
    final target = state.messages[i];
    if (target.pending || target.isDeleted) return;

    final add = !target.hasReaction(event.emoji, userId);
    emit(state.copyWith(
      messages: _replace(_applyReaction(
        target,
        emoji: event.emoji,
        userId: userId,
        add: add,
      )),
    ));

    final result = await _toggleReaction(ToggleReactionParams(
      messageId: target.id,
      emoji: event.emoji,
      add: add,
    ));
    result.fold(
      (failure) => emit(state.copyWith(
        messages: _replace(target),
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  /// The message list with [message] swapped in for the entry sharing its id.
  List<ChatMessage> _replace(ChatMessage message) =>
      [for (final m in state.messages) m.id == message.id ? message : m];

  void _onSyncResult(_ChatSyncResult event, Emitter<ChatState> emit) {
    // The outbox is the authoritative signal that a send landed. Waiting for
    // the realtime echo instead left the clock showing on a message that had
    // in fact been delivered, whenever that echo was missed or slow. The row
    // stays `local` so the echo can still swap in the server copy.
    final succeeded = event.result.outcome == SyncOutcome.success;
    final list = state.messages
        .map((m) => m.id == event.result.id
            ? m.copyWith(pending: false, failed: !succeeded)
            : m)
        .toList();
    emit(state.copyWith(messages: list));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _reactionSub?.cancel();
    _syncSub?.cancel();
    return super.close();
  }
}
