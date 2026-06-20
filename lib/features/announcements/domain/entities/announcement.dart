import 'package:equatable/equatable.dart';

/// A campus announcement. Mirrors the `announcements` table.
class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.category,
    required this.createdAt,
    required this.likes,
    required this.bookmarks,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String content;
  final String author;
  final String category;
  final DateTime createdAt;
  final int likes;
  final int bookmarks;

  /// Optional image (Supabase Storage public URL).
  final String? imageUrl;

  Announcement copyWith({int? likes, int? bookmarks}) {
    return Announcement(
      id: id,
      title: title,
      content: content,
      author: author,
      category: category,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      bookmarks: bookmarks ?? this.bookmarks,
      imageUrl: imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        author,
        category,
        createdAt,
        likes,
        bookmarks,
        imageUrl,
      ];
}

/// The current user's like/bookmark sets, used to render filled/outlined icons.
class AnnouncementInteractions extends Equatable {
  const AnnouncementInteractions({
    this.likedIds = const {},
    this.bookmarkedIds = const {},
  });

  final Set<String> likedIds;
  final Set<String> bookmarkedIds;

  @override
  List<Object?> get props => [likedIds, bookmarkedIds];
}
