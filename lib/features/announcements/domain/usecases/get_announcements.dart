import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Loads all announcements (newest first).
class GetAnnouncements implements UseCase<List<Announcement>, NoParams> {
  const GetAnnouncements(this._repository);

  final AnnouncementRepository _repository;

  @override
  Future<Either<Failure, List<Announcement>>> call(NoParams params) =>
      _repository.getAnnouncements();
}

/// Loads the current user's like/bookmark sets.
class GetInteractions implements UseCase<AnnouncementInteractions, NoParams> {
  const GetInteractions(this._repository);

  final AnnouncementRepository _repository;

  @override
  Future<Either<Failure, AnnouncementInteractions>> call(NoParams params) =>
      _repository.getInteractions();
}
