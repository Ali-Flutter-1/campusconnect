import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/notice.dart';
import '../../domain/repositories/notice_repository.dart';
import '../datasources/notice_local_data_source.dart';
import '../datasources/notice_remote_data_source.dart';

class NoticeRepositoryImpl implements NoticeRepository {
  const NoticeRepositoryImpl(this._remote, this._local, this._networkInfo);

  final NoticeRemoteDataSource _remote;
  final NoticeLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  List<Notice> getCachedNotices() => _local.getCached();

  @override
  Future<Either<Failure, List<Notice>>> getNotices({
    int limit = 20,
    int offset = 0,
  }) async {
    if (!await _networkInfo.isConnected) {
      final cached = _local.getCached();
      return offset == 0 && cached.isNotEmpty
          ? Right(cached)
          : const Left(NetworkFailure());
    }
    try {
      final items = await _remote.getNotices(limit: limit, offset: offset);
      if (offset == 0) await _local.cache(items);
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Notice>> createNotice({
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  }) =>
      _guard(() => _remote.createNotice(
            title: title,
            content: content,
            category: category,
            priority: priority,
            department: department,
          ));

  @override
  Future<Either<Failure, Notice>> updateNotice({
    required String id,
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  }) =>
      _guard(() => _remote.updateNotice(
            id: id,
            title: title,
            content: content,
            category: category,
            priority: priority,
            department: department,
          ));

  @override
  Future<Either<Failure, Unit>> deleteNotice(String noticeId) =>
      _guard(() async {
        await _remote.deleteNotice(noticeId);
        return unit;
      });

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
}
