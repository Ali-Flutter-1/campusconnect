part of 'announcements_bloc.dart';

sealed class AnnouncementsEvent extends Equatable {
  const AnnouncementsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load (announcements + the user's like/bookmark sets).
class AnnouncementsLoadRequested extends AnnouncementsEvent {
  const AnnouncementsLoadRequested();
}

/// Pull-to-refresh.
class AnnouncementsRefreshRequested extends AnnouncementsEvent {
  const AnnouncementsRefreshRequested();
}

class AnnouncementLikeToggled extends AnnouncementsEvent {
  const AnnouncementLikeToggled(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class AnnouncementBookmarkToggled extends AnnouncementsEvent {
  const AnnouncementBookmarkToggled(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// Admin-only: create a new announcement (author comes from the signed-in user).
class AnnouncementCreated extends AnnouncementsEvent {
  const AnnouncementCreated({
    required this.title,
    required this.content,
    required this.category,
    required this.author,
    this.imageBytes,
    this.imageExt,
  });

  final String title;
  final String content;
  final String category;
  final String author;
  final Uint8List? imageBytes;
  final String? imageExt;

  @override
  List<Object?> get props =>
      [title, content, category, author, imageBytes, imageExt];
}

/// Admin-only: delete an announcement.
class AnnouncementDeleted extends AnnouncementsEvent {
  const AnnouncementDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
