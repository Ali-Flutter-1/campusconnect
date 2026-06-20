import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/announcement_repository.dart';

class ToggleInteractionParams extends Equatable {
  const ToggleInteractionParams({required this.announcementId, required this.active});

  /// Target announcement.
  final String announcementId;

  /// The desired new state (true = liked/bookmarked).
  final bool active;

  @override
  List<Object?> get props => [announcementId, active];
}

/// Likes/unlikes an announcement (writes `user_likes` + the like-count RPC).
class ToggleLike implements UseCase<Unit, ToggleInteractionParams> {
  const ToggleLike(this._repository);

  final AnnouncementRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ToggleInteractionParams params) =>
      _repository.toggleLike(
        announcementId: params.announcementId,
        liked: params.active,
      );
}

/// Bookmarks/un-bookmarks an announcement (writes `user_bookmarks` + the
/// bookmark-count RPC).
class ToggleBookmark implements UseCase<Unit, ToggleInteractionParams> {
  const ToggleBookmark(this._repository);

  final AnnouncementRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ToggleInteractionParams params) =>
      _repository.toggleBookmark(
        announcementId: params.announcementId,
        bookmarked: params.active,
      );
}
