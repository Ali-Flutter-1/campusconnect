import 'package:equatable/equatable.dart';

/// A complaint / request submission. Mirrors the `complaints` table.
///
/// [authorName] / [authorEmail] are only populated in the admin "Approvals"
/// view (joined from `profiles`); they stay null for a student's own list.
class Complaint extends Equatable {
  const Complaint({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.authorName,
    this.authorEmail,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;

  /// 'open', 'in_progress', 'resolved' or 'rejected'.
  final String status;
  final DateTime createdAt;
  final String? authorName;
  final String? authorEmail;

  bool get isResolved => status == 'resolved';
  bool get isRejected => status == 'rejected';

  /// Still needs admin attention (pending or in progress).
  bool get isActive => status == 'open' || status == 'in_progress';

  Complaint copyWith({String? status}) => Complaint(
        id: id,
        userId: userId,
        title: title,
        description: description,
        category: category,
        status: status ?? this.status,
        createdAt: createdAt,
        authorName: authorName,
        authorEmail: authorEmail,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        category,
        status,
        createdAt,
        authorName,
        authorEmail,
      ];
}
