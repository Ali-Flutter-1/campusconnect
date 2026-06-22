import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notice.dart';

/// Contract for reading notices, plus admin create/delete.
abstract interface class NoticeRepository {
  Future<Either<Failure, List<Notice>>> getNotices({int limit, int offset});

  /// Instantly-available cached first page.
  List<Notice> getCachedNotices();

  // Admin-only.
  Future<Either<Failure, Notice>> createNotice({
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  });

  Future<Either<Failure, Notice>> updateNotice({
    required String id,
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  });

  Future<Either<Failure, Unit>> deleteNotice(String noticeId);
}
