import '../../domain/entities/complaint.dart';

/// Data-layer [Complaint] with Supabase (de)serialization.
class ComplaintModel extends Complaint {
  const ComplaintModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.category,
    required super.status,
    required super.createdAt,
    super.authorName,
    super.authorEmail,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'general',
      status: (json['status'] as String?) ?? 'open',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      // Set only in the admin view, where rows are enriched from `profiles`.
      authorName: json['author_name'] as String?,
      authorEmail: json['author_email'] as String?,
    );
  }

  /// Full row shape for the Hive cache (round-trips through [fromJson]).
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'author_name': authorName,
        'author_email': authorEmail,
      };

  static Map<String, dynamic> toInsert({
    required String userId,
    required String title,
    required String description,
    required String category,
  }) =>
      {
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'status': 'open',
      };
}
