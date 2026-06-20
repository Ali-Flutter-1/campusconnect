import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class CreateAnnouncementParams extends Equatable {
  const CreateAnnouncementParams({
    required this.title,
    required this.content,
    required this.category,
    required this.author,
    this.imageBytes,
    this.imageExt,
  });

  final String title;
  final String content;
  final String category;
  final String author;
  final Uint8List? imageBytes;
  final String? imageExt;

  @override
  List<Object?> get props =>
      [title, content, category, author, imageBytes, imageExt];
}

/// Admin-only: publishes a new announcement.
class CreateAnnouncement
    implements UseCase<Announcement, CreateAnnouncementParams> {
  const CreateAnnouncement(this._repository);

  final AnnouncementRepository _repository;

  @override
  Future<Either<Failure, Announcement>> call(CreateAnnouncementParams params) =>
      _repository.createAnnouncement(
        title: params.title,
        content: params.content,
        category: params.category,
        author: params.author,
        imageBytes: params.imageBytes,
        imageExt: params.imageExt,
      );
}

/// Admin-only: removes an announcement.
class DeleteAnnouncement implements UseCase<Unit, String> {
  const DeleteAnnouncement(this._repository);

  final AnnouncementRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String announcementId) =>
      _repository.deleteAnnouncement(announcementId);
}
