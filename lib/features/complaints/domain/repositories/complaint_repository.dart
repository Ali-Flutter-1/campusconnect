import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/complaint.dart';

/// Contract for the current user's complaints/feedback.
abstract interface class ComplaintRepository {
  /// The signed-in user's own complaints (newest first).
  Future<Either<Failure, List<Complaint>>> getMyComplaints();

  Future<Either<Failure, Complaint>> createComplaint({
    required String title,
    required String description,
    required String category,
  });

  /// Admin-only: the cached approvals queue, for instant/offline paint.
  List<Complaint> getCachedComplaints();

  /// Admin-only: every request (newest first) with submitter details.
  Future<Either<Failure, List<Complaint>>> getAllComplaints();

  /// Admin-only: set a request's [status].
  Future<Either<Failure, Complaint>> updateStatus({
    required String id,
    required String status,
  });
}
