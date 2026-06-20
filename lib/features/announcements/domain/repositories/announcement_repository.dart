import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/announcement.dart';

/// Contract for reading announcements and the user's interactions with them,
/// plus admin-only create/delete. Implemented in the data layer.
abstract interface class AnnouncementRepository {
  Future<Either<Failure, List<Announcement>>> getAnnouncements();

  /// The signed-in user's liked/bookmarked announcement ids (empty when
  /// signed out).
  Future<Either<Failure, AnnouncementInteractions>> getInteractions();

  Future<Either<Failure, Unit>> toggleLike({
    required String announcementId,
    required bool liked,
  });

  Future<Either<Failure, Unit>> toggleBookmark({
    required String announcementId,
    required bool bookmarked,
  });

  // Admin-only.
  Future<Either<Failure, Announcement>> createAnnouncement({
    required String title,
    required String content,
    required String category,
    required String author,
    Uint8List? imageBytes,
    String? imageExt,
  });

  Future<Either<Failure, Unit>> deleteAnnouncement(String announcementId);
}
