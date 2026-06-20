part of 'announcements_bloc.dart';

enum AnnouncementsStatus { initial, loading, success, failure }

class AnnouncementsState extends Equatable {
  const AnnouncementsState({
    this.status = AnnouncementsStatus.initial,
    this.announcements = const [],
    this.interactions = const AnnouncementInteractions(),
    this.errorMessage,
  });

  final AnnouncementsStatus status;
  final List<Announcement> announcements;
  final AnnouncementInteractions interactions;
  final String? errorMessage;

  bool isLiked(String id) => interactions.likedIds.contains(id);
  bool isBookmarked(String id) => interactions.bookmarkedIds.contains(id);

  AnnouncementsState copyWith({
    AnnouncementsStatus? status,
    List<Announcement>? announcements,
    AnnouncementInteractions? interactions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnnouncementsState(
      status: status ?? this.status,
      announcements: announcements ?? this.announcements,
      interactions: interactions ?? this.interactions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, announcements, interactions, errorMessage];
}
