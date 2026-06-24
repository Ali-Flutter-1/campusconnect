import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/complaint.dart';
import '../repositories/complaint_repository.dart';

class GetMyComplaints implements UseCase<List<Complaint>, NoParams> {
  const GetMyComplaints(this._repository);

  final ComplaintRepository _repository;

  @override
  Future<Either<Failure, List<Complaint>>> call(NoParams params) =>
      _repository.getMyComplaints();
}

class CreateComplaintParams extends Equatable {
  const CreateComplaintParams({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final String category;

  @override
  List<Object?> get props => [title, description, category];
}

class CreateComplaint implements UseCase<Complaint, CreateComplaintParams> {
  const CreateComplaint(this._repository);

  final ComplaintRepository _repository;

  @override
  Future<Either<Failure, Complaint>> call(CreateComplaintParams params) =>
      _repository.createComplaint(
        title: params.title,
        description: params.description,
        category: params.category,
      );
}

/// Admin-only: load every submitted request for triage.
class GetAllComplaints implements UseCase<List<Complaint>, NoParams> {
  const GetAllComplaints(this._repository);

  final ComplaintRepository _repository;

  @override
  Future<Either<Failure, List<Complaint>>> call(NoParams params) =>
      _repository.getAllComplaints();
}

/// Admin-only: synchronous cached approvals queue, for instant/offline paint.
class GetCachedComplaints {
  const GetCachedComplaints(this._repository);

  final ComplaintRepository _repository;

  List<Complaint> call() => _repository.getCachedComplaints();
}

class UpdateComplaintStatusParams extends Equatable {
  const UpdateComplaintStatusParams({required this.id, required this.status});

  final String id;
  final String status;

  @override
  List<Object?> get props => [id, status];
}

/// Admin-only: approve / resolve / reject / reopen a request.
class UpdateComplaintStatus
    implements UseCase<Complaint, UpdateComplaintStatusParams> {
  const UpdateComplaintStatus(this._repository);

  final ComplaintRepository _repository;

  @override
  Future<Either<Failure, Complaint>> call(UpdateComplaintStatusParams params) =>
      _repository.updateStatus(id: params.id, status: params.status);
}
