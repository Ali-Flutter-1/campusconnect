part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Begin: load history for [room] and subscribe to realtime changes.
class ChatStarted extends ChatEvent {
  const ChatStarted({this.room = 'global'});
  final String room;

  @override
  List<Object?> get props => [room];
}

/// Internal: a message was inserted, edited or removed on the realtime channel.
class ChatMessageChanged extends ChatEvent {
  const ChatMessageChanged(this.change);
  final ChatChange change;

  @override
  List<Object?> get props => [change.kind, change.messageId];
}

/// Internal: someone added or removed a reaction on the realtime channel.
class ChatReactionChanged extends ChatEvent {
  const ChatReactionChanged(this.change);
  final ReactionChange change;

  @override
  List<Object?> get props =>
      [change.messageId, change.userId, change.emoji, change.added];
}

/// Load an older page of history (scrolled toward the top).
class ChatOlderRequested extends ChatEvent {
  const ChatOlderRequested();
}

class ChatSendRequested extends ChatEvent {
  const ChatSendRequested(this.content);
  final String content;

  @override
  List<Object?> get props => [content];
}

/// Re-queue a message whose offline send had permanently failed.
class ChatRetryRequested extends ChatEvent {
  const ChatRetryRequested(this.messageId);
  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Compose the next message as a reply to [message]; clears any active edit.
class ChatReplyStarted extends ChatEvent {
  const ChatReplyStarted(this.message);
  final ChatMessage message;

  @override
  List<Object?> get props => [message.id];
}

/// Put [message] into the composer for editing; clears any active reply.
class ChatEditStarted extends ChatEvent {
  const ChatEditStarted(this.message);
  final ChatMessage message;

  @override
  List<Object?> get props => [message.id];
}

/// Drop the pending reply and/or edit.
class ChatComposerCleared extends ChatEvent {
  const ChatComposerCleared();
}

/// Commit the in-progress edit with [content].
class ChatEditSubmitted extends ChatEvent {
  const ChatEditSubmitted(this.content);
  final String content;

  @override
  List<Object?> get props => [content];
}

/// Soft-delete one of the user's own messages.
class ChatDeleteRequested extends ChatEvent {
  const ChatDeleteRequested(this.messageId);
  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Add the current user's [emoji] to a message, or remove it if already there.
class ChatReactionToggled extends ChatEvent {
  const ChatReactionToggled({required this.messageId, required this.emoji});
  final String messageId;
  final String emoji;

  @override
  List<Object?> get props => [messageId, emoji];
}

/// Internal: the outbox finished flushing a chat message (success/fail).
class _ChatSyncResult extends ChatEvent {
  const _ChatSyncResult(this.result);
  final SyncResult result;

  @override
  List<Object?> get props => [result.id, result.outcome];
}
