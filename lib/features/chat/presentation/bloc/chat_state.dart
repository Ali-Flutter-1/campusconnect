part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.currentUserId,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final ChatStatus status;

  /// Newest-first (index 0 = newest); the page renders this in a reversed list.
  final List<ChatMessage> messages;
  final String? currentUserId;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? errorMessage;

  bool isMine(ChatMessage m) => m.senderId != null && m.senderId == currentUserId;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? currentUserId,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentUserId: currentUserId ?? this.currentUserId,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        currentUserId,
        hasReachedMax,
        isLoadingMore,
        errorMessage,
      ];
}
