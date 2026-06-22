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
    );
  }

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
