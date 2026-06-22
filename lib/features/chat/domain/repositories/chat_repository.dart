import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';

/// Contract for the realtime chat. Implemented in the data layer.
abstract interface class ChatRepository {
  /// The id of the signed-in user (for "is this my message?" checks).
  String? get currentUserId;

  /// Loads a page of messages in [room], newest first. [before] loads the page
  /// older than that timestamp (cursor pagination).
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String room, {
    int limit,
    DateTime? before,
  });

  /// A live stream of newly-inserted messages in [room] (Supabase Realtime).
  Stream<ChatMessage> watchMessages(String room);

  /// Sends a message to [room] as the current user.
  Future<Either<Failure, Unit>> sendMessage({
    required String room,
    required String content,
  });
}
