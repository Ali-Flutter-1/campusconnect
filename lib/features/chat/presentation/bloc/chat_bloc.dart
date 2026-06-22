import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/chat_usecases.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Drives the realtime chat: loads history, subscribes to new messages via
/// Supabase Realtime, and sends messages.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required GetMessages getMessages,
    required SendMessage sendMessage,
    required WatchMessages watchMessages,
    required GetCurrentUserId getCurrentUserId,
  })  : _getMessages = getMessages,
        _sendMessage = sendMessage,
        _watchMessages = watchMessages,
        _getCurrentUserId = getCurrentUserId,
        super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatOlderRequested>(_onOlderRequested);
    on<ChatSendRequested>(_onSendRequested);
  }

  final GetMessages _getMessages;
  final SendMessage _sendMessage;
  final WatchMessages _watchMessages;
  final GetCurrentUserId _getCurrentUserId;

  StreamSubscription<ChatMessage>? _sub;
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
      (messages) => emit(state.copyWith(
        status: ChatStatus.success,
        messages: messages,
        hasReachedMax: messages.length < AppConstants.pageSize,
        clearError: true,
      )),
    );

    await _sub?.cancel();
    _sub = _watchMessages(_room).listen(
      (message) => add(ChatMessageReceived(message)),
    );
  }

  void _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    // Ignore duplicates (the insert may also arrive in the initial fetch).
    if (state.messages.any((m) => m.id == event.message.id)) return;
    // Newest goes to the front (bottom of the reversed list).
    emit(state.copyWith(messages: [event.message, ...state.messages]));
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
    final result = await _sendMessage(
      SendMessageParams(room: _room, content: content),
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
