import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_local_data_source.dart';
import '../datasources/announcement_remote_data_source.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl(this._remote, this._local, this._networkInfo);

  final AnnouncementRemoteDataSource _remote;
  final AnnouncementLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  List<Announcement> getCachedAnnouncements() => _local.getCached();

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements({
    int limit = 20,
    int offset = 0,
  }) async {
    if (!await _networkInfo.isConnected) {
      // Offline: serve the cached first page (if any) rather than erroring.
      final cached = _local.getCached();
      return offset == 0 && cached.isNotEmpty
          ? Right(cached)
          : const Left(NetworkFailure());
    }
    try {
      final items = await _remote.getAnnouncements(limit: limit, offset: offset);
      if (offset == 0) await _local.cache(items);
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AnnouncementInteractions>> getInteractions() =>
      _guard(_remote.getInteractions);

  @override
  Future<Either<Failure, Unit>> toggleLike({
    required String announcementId,
    required bool liked,
  }) =>
      _guardUnit(() => _remote.toggleLike(
            announcementId: announcementId,
            liked: liked,
          ));

  @override
  Future<Either<Failure, Unit>> toggleBookmark({
    required String announcementId,
    required bool bookmarked,
  }) =>
      _guardUnit(() => _remote.toggleBookmark(
            announcementId: announcementId,
            bookmarked: bookmarked,
          ));

  @override
  Future<Either<Failure, Announcement>> createAnnouncement({
    required String title,
    required String content,
    required String category,
    required String author,
    Uint8List? imageBytes,
    String? imageExt,
  }) =>
      _guard(() => _remote.createAnnouncement(
            title: title,
            content: content,
            category: category,
            author: author,
            imageBytes: imageBytes,
            imageExt: imageExt,
          ));

  @override
  Future<Either<Failure, Announcement>> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    required String category,
  }) =>
      _guard(() => _remote.updateAnnouncement(
            id: id,
            title: title,
            content: content,
            category: category,
          ));

  @override
  Future<Either<Failure, Unit>> deleteAnnouncement(String announcementId) =>
      _guardUnit(() => _remote.deleteAnnouncement(announcementId));

  /// Online check + exception→failure mapping for value-returning calls.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  /// Same as [_guard] but for `void` actions, returning `unit` on success.
  Future<Either<Failure, Unit>> _guardUnit(Future<void> Function() action) =>
      _guard(() async {
        await action();
        return unit;
      });
}
