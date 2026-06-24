import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remote, this._networkInfo);

  final ChatRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  String? get currentUserId => _remote.currentUserId;

  @override
  Stream<ChatMessage> watchMessages(String room) =>
      _remote.watchMessages(room);

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String room, {
    int limit = 20,
    DateTime? before,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.getMessages(room, limit: limit, before: before));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendMessage({
    required String room,
    required String content,
  }) async {
    // No connectivity pre-check: the outbox owns retries, so a failed send
    // (incl. offline) surfaces as a Failure the SyncService can re-queue.
    try {
      await _remote.sendMessage(room: room, content: content);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
