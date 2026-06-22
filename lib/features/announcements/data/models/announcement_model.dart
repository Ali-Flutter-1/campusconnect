import '../../domain/entities/announcement.dart';

/// Data-layer [Announcement] with Supabase (de)serialization.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.content,
    required super.author,
    required super.category,
    required super.createdAt,
    required super.likes,
    required super.bookmarks,
    super.imageUrl,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      author: (json['author'] as String?) ?? 'Admin',
      category: (json['category'] as String?) ?? 'general',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      bookmarks: (json['bookmarks'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }

  /// Full row shape (snake_case) for caching; round-trips through [fromJson].
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'author': author,
        'category': category,
        'likes': likes,
        'bookmarks': bookmarks,
        'created_at': createdAt.toUtc().toIso8601String(),
        'image_url': imageUrl,
      };

  /// Fields sent when an admin creates an announcement (counts/id/timestamp are
  /// defaulted by the database).
  static Map<String, dynamic> toInsert({
    required String title,
    required String content,
    required String category,
    required String author,
    String? imageUrl,
  }) =>
      {
        'title': title,
        'content': content,
        'category': category,
        'author': author,
        'image_url': ?imageUrl,
      };
}
