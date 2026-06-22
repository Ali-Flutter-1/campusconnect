import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notice.dart';
import '../repositories/notice_repository.dart';

class GetNoticesParams extends Equatable {
  const GetNoticesParams({
    this.limit = AppConstants.pageSize,
    this.offset = 0,
  });

  final int limit;
  final int offset;

  @override
  List<Object?> get props => [limit, offset];
}

class GetNotices implements UseCase<List<Notice>, GetNoticesParams> {
  const GetNotices(this._repository);

  final NoticeRepository _repository;

  @override
  Future<Either<Failure, List<Notice>>> call(GetNoticesParams params) =>
      _repository.getNotices(limit: params.limit, offset: params.offset);
}

/// Synchronous cached first page (instant first paint).
class GetCachedNotices {
  const GetCachedNotices(this._repository);

  final NoticeRepository _repository;

  List<Notice> call() => _repository.getCachedNotices();
}

class CreateNoticeParams extends Equatable {
  const CreateNoticeParams({
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.department,
  });

  final String title;
  final String content;
  final String category;
  final String priority;
  final String? department;

  @override
  List<Object?> get props => [title, content, category, priority, department];
}

/// Admin-only: posts a notice.
class CreateNotice implements UseCase<Notice, CreateNoticeParams> {
  const CreateNotice(this._repository);

  final NoticeRepository _repository;

  @override
  Future<Either<Failure, Notice>> call(CreateNoticeParams params) =>
      _repository.createNotice(
        title: params.title,
        content: params.content,
        category: params.category,
        priority: params.priority,
        department: params.department,
      );
}

class UpdateNoticeParams extends Equatable {
  const UpdateNoticeParams({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.department,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final String priority;
  final String? department;

  @override
  List<Object?> get props =>
      [id, title, content, category, priority, department];
}

/// Admin-only: edits a notice.
class UpdateNotice implements UseCase<Notice, UpdateNoticeParams> {
  const UpdateNotice(this._repository);

  final NoticeRepository _repository;

  @override
  Future<Either<Failure, Notice>> call(UpdateNoticeParams params) =>
      _repository.updateNotice(
        id: params.id,
        title: params.title,
        content: params.content,
        category: params.category,
        priority: params.priority,
        department: params.department,
      );
}

/// Admin-only: removes a notice.
class DeleteNotice implements UseCase<Unit, String> {
  const DeleteNotice(this._repository);

  final NoticeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String noticeId) =>
      _repository.deleteNotice(noticeId);
}
