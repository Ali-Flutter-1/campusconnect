import 'package:equatable/equatable.dart';

/// A complaint / feedback submission. Mirrors the `complaints` table.
class Complaint extends Equatable {
  const Complaint({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;

  /// 'open', 'in_progress' or 'resolved'.
  final String status;
  final DateTime createdAt;

  bool get isResolved => status == 'resolved';
  bool get isActive => !isResolved;

  @override
  List<Object?> get props =>
      [id, userId, title, description, category, status, createdAt];
}
