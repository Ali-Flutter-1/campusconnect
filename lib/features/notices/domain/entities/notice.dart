import 'package:equatable/equatable.dart';

/// An official campus notice. Mirrors the `notices` table.
class Notice extends Equatable {
  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.department,
  });

  final String id;
  final String title;
  final String content;

  /// 'normal' or 'high'. High-priority notices are shown pinned.
  final String priority;
  final String category;
  final DateTime createdAt;
  final String? department;

  bool get isPinned => priority == 'high';

  @override
  List<Object?> get props =>
      [id, title, content, priority, category, createdAt, department];
}
