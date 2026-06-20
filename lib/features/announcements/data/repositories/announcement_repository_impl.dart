import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_data_source.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl(this._remote, this._networkInfo);

  final AnnouncementRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements() =>
      _guard(_remote.getAnnouncements);

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
