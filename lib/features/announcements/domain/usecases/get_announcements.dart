import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncementsParams extends Equatable {
  const GetAnnouncementsParams({
    this.limit = AppConstants.pageSize,
    this.offset = 0,
  });

  final int limit;
  final int offset;

  @override
  List<Object?> get props => [limit, offset];
}

/// Loads a page of announcements (newest first).
class GetAnnouncements
    implements UseCase<List<Announcement>, GetAnnouncementsParams> {
  const GetAnnouncements(this._repository);

  final AnnouncementRepository _repository;

  @override
  Future<Either<Failure, List<Announcement>>> call(
    GetAnnouncementsParams params,
  ) =>
      _repository.getAnnouncements(limit: params.limit, offset: params.offset);
}

/// Synchronous cached first page (instant first paint).
class GetCachedAnnouncements {
  const GetCachedAnnouncements(this._repository);

  final AnnouncementRepository _repository;

  List<Announcement> call() => _repository.getCachedAnnouncements();
}

/// Loads the current user's like/bookmark sets.
class GetInteractions implements UseCase<AnnouncementInteractions, NoParams> {
  const GetInteractions(this._repository);

  final AnnouncementRepository _repository;

  @override
  Future<Either<Failure, AnnouncementInteractions>> call(NoParams params) =>
      _repository.getInteractions();
}
