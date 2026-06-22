part of 'announcements_bloc.dart';

enum AnnouncementsStatus { initial, loading, success, failure }

class AnnouncementsState extends Equatable {
  const AnnouncementsState({
    this.status = AnnouncementsStatus.initial,
    this.announcements = const [],
    this.interactions = const AnnouncementInteractions(),
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final AnnouncementsStatus status;
  final List<Announcement> announcements;
  final AnnouncementInteractions interactions;

  /// True once a fetched page returned fewer than a full page (no more rows).
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? errorMessage;

  bool isLiked(String id) => interactions.likedIds.contains(id);
  bool isBookmarked(String id) => interactions.bookmarkedIds.contains(id);

  AnnouncementsState copyWith({
    AnnouncementsStatus? status,
    List<Announcement>? announcements,
    AnnouncementInteractions? interactions,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnnouncementsState(
      status: status ?? this.status,
      announcements: announcements ?? this.announcements,
      interactions: interactions ?? this.interactions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        announcements,
        interactions,
        hasReachedMax,
        isLoadingMore,
        errorMessage,
      ];
}
