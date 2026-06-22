import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/usecases/get_announcements.dart';
import '../../domain/usecases/manage_announcements.dart';
import '../../domain/usecases/toggle_interactions.dart';

part 'announcements_event.dart';
part 'announcements_state.dart';

/// Drives the Announcements screen: loading, pull-to-refresh, optimistic
/// like/bookmark toggles, and admin create/delete.
class AnnouncementsBloc extends Bloc<AnnouncementsEvent, AnnouncementsState> {
  AnnouncementsBloc({
    required GetAnnouncements getAnnouncements,
    required GetCachedAnnouncements getCachedAnnouncements,
    required GetInteractions getInteractions,
    required ToggleLike toggleLike,
    required ToggleBookmark toggleBookmark,
    required CreateAnnouncement createAnnouncement,
    required UpdateAnnouncement updateAnnouncement,
    required DeleteAnnouncement deleteAnnouncement,
  })  : _getAnnouncements = getAnnouncements,
        _getCachedAnnouncements = getCachedAnnouncements,
        _getInteractions = getInteractions,
        _toggleLike = toggleLike,
        _toggleBookmark = toggleBookmark,
        _createAnnouncement = createAnnouncement,
        _updateAnnouncement = updateAnnouncement,
        _deleteAnnouncement = deleteAnnouncement,
        super(const AnnouncementsState()) {
    on<AnnouncementsLoadRequested>(_onLoad);
    on<AnnouncementsRefreshRequested>(_onRefresh);
    on<AnnouncementsLoadMoreRequested>(_onLoadMore);
    on<AnnouncementLikeToggled>(_onLikeToggled);
    on<AnnouncementBookmarkToggled>(_onBookmarkToggled);
    on<AnnouncementCreated>(_onCreated);
    on<AnnouncementUpdated>(_onUpdated);
    on<AnnouncementDeleted>(_onDeleted);
  }

  final GetAnnouncements _getAnnouncements;
  final GetCachedAnnouncements _getCachedAnnouncements;
  final GetInteractions _getInteractions;
  final ToggleLike _toggleLike;
  final ToggleBookmark _toggleBookmark;
  final CreateAnnouncement _createAnnouncement;
  final UpdateAnnouncement _updateAnnouncement;
  final DeleteAnnouncement _deleteAnnouncement;

  Future<void> _onLoad(
    AnnouncementsLoadRequested event,
    Emitter<AnnouncementsState> emit,
  ) async {
    // Cache-first: show the cached page instantly, then refresh from network.
    final cached = _getCachedAnnouncements();
    if (cached.isNotEmpty) {
      emit(state.copyWith(
        status: AnnouncementsStatus.success,
        announcements: cached,
      ));
    } else {
      emit(state.copyWith(
        status: AnnouncementsStatus.loading,
        clearError: true,
      ));
    }
    await _load(emit);
  }

  Future<void> _onRefresh(
    AnnouncementsRefreshRequested event,
    Emitter<AnnouncementsState> emit,
  ) =>
      _load(emit);

  Future<void> _load(Emitter<AnnouncementsState> emit) async {
    final result = await _getAnnouncements(const GetAnnouncementsParams());
    await result.fold(
      (failure) async => emit(state.copyWith(
        status: AnnouncementsStatus.failure,
        errorMessage: failure.message,
      )),
      (announcements) async {
        final interactions = await _getInteractions(const NoParams());
        emit(state.copyWith(
          status: AnnouncementsStatus.success,
          announcements: announcements,
          interactions: interactions.getOrElse(
            () => const AnnouncementInteractions(),
          ),
          hasReachedMax: announcements.length < AppConstants.pageSize,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadMore(
    AnnouncementsLoadMoreRequested event,
    Emitter<AnnouncementsState> emit,
  ) async {
    if (state.hasReachedMax || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getAnnouncements(
      GetAnnouncementsParams(offset: state.announcements.length),
    );
    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        announcements: [...state.announcements, ...page],
        isLoadingMore: false,
        hasReachedMax: page.length < AppConstants.pageSize,
      )),
    );
  }

  Future<void> _onLikeToggled(
    AnnouncementLikeToggled event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final wasLiked = state.isLiked(event.id);
    final previous = state;

    // Optimistic update: flip the set + adjust the count immediately.
    emit(_applyInteraction(
      id: event.id,
      liked: !wasLiked,
      countDelta: wasLiked ? -1 : 1,
      isLike: true,
    ));

    final result = await _toggleLike(
      ToggleInteractionParams(announcementId: event.id, active: !wasLiked),
    );
    result.fold((failure) => emit(previous.copyWith(errorMessage: failure.message)), (_) {});
  }

  Future<void> _onBookmarkToggled(
    AnnouncementBookmarkToggled event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final wasBookmarked = state.isBookmarked(event.id);
    final previous = state;

    emit(_applyInteraction(
      id: event.id,
      bookmarked: !wasBookmarked,
      countDelta: wasBookmarked ? -1 : 1,
      isLike: false,
    ));

    final result = await _toggleBookmark(
      ToggleInteractionParams(announcementId: event.id, active: !wasBookmarked),
    );
    result.fold((failure) => emit(previous.copyWith(errorMessage: failure.message)), (_) {});
  }

  Future<void> _onCreated(
    AnnouncementCreated event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final result = await _createAnnouncement(CreateAnnouncementParams(
      title: event.title,
      content: event.content,
      category: event.category,
      author: event.author,
      imageBytes: event.imageBytes,
      imageExt: event.imageExt,
    ));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (created) => emit(state.copyWith(
        announcements: [created, ...state.announcements],
        clearError: true,
      )),
    );
  }

  Future<void> _onUpdated(
    AnnouncementUpdated event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final result = await _updateAnnouncement(UpdateAnnouncementParams(
      id: event.id,
      title: event.title,
      content: event.content,
      category: event.category,
    ));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updated) => emit(state.copyWith(
        announcements: state.announcements
            .map((a) => a.id == updated.id ? updated : a)
            .toList(),
        clearError: true,
      )),
    );
  }

  Future<void> _onDeleted(
    AnnouncementDeleted event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final previous = state;
    emit(state.copyWith(
      announcements:
          state.announcements.where((a) => a.id != event.id).toList(),
    ));
    final result = await _deleteAnnouncement(event.id);
    result.fold(
      (failure) => emit(previous.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }

  /// Produces a new state with the like/bookmark set flipped for [id] and the
  /// matching count adjusted by [countDelta].
  AnnouncementsState _applyInteraction({
    required String id,
    required int countDelta,
    required bool isLike,
    bool? liked,
    bool? bookmarked,
  }) {
    final liked0 = {...state.interactions.likedIds};
    final bookmarked0 = {...state.interactions.bookmarkedIds};

    if (liked != null) {
      liked ? liked0.add(id) : liked0.remove(id);
    }
    if (bookmarked != null) {
      bookmarked ? bookmarked0.add(id) : bookmarked0.remove(id);
    }

    final announcements = state.announcements.map((a) {
      if (a.id != id) return a;
      return isLike
          ? a.copyWith(likes: (a.likes + countDelta).clamp(0, 1 << 30))
          : a.copyWith(bookmarks: (a.bookmarks + countDelta).clamp(0, 1 << 30));
    }).toList();

    return state.copyWith(
      announcements: announcements,
      interactions: AnnouncementInteractions(
        likedIds: liked0,
        bookmarkedIds: bookmarked0,
      ),
    );
  }
}
