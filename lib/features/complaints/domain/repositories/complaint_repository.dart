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
}
