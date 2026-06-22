import '../../domain/entities/notice.dart';

/// Data-layer [Notice] with Supabase (de)serialization.
class NoticeModel extends Notice {
  const NoticeModel({
    required super.id,
    required super.title,
    required super.content,
    required super.priority,
    required super.category,
    required super.createdAt,
    super.department,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      priority: (json['priority'] as String?) ?? 'normal',
      category: (json['category'] as String?) ?? 'general',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      department: json['department'] as String?,
    );
  }

  /// Full row shape (snake_case) for caching; round-trips through [fromJson].
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'priority': priority,
        'category': category,
        'department': department,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  static Map<String, dynamic> toInsert({
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  }) =>
      {
        'title': title,
        'content': content,
        'category': category,
        'priority': priority,
        'department': ?department,
      };
}
