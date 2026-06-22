part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Begin: load history for [room] and subscribe to realtime inserts.
class ChatStarted extends ChatEvent {
  const ChatStarted({this.room = 'global'});
  final String room;

  @override
  List<Object?> get props => [room];
}

/// Internal: a new message arrived over the realtime channel.
class ChatMessageReceived extends ChatEvent {
  const ChatMessageReceived(this.message);
  final ChatMessage message;

  @override
  List<Object?> get props => [message];
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
