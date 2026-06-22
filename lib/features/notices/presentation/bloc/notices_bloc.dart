import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/notice.dart';
import '../../domain/usecases/notice_usecases.dart';

part 'notices_event.dart';
part 'notices_state.dart';

/// Drives the Notices screen: paginated load + category filter + text search
/// (client-side over the loaded pages), and admin create/edit/delete.
class NoticesBloc extends Bloc<NoticesEvent, NoticesState> {
  NoticesBloc({
    required GetNotices getNotices,
    required GetCachedNotices getCachedNotices,
    required CreateNotice createNotice,
    required UpdateNotice updateNotice,
    required DeleteNotice deleteNotice,
  })  : _getNotices = getNotices,
        _getCachedNotices = getCachedNotices,
        _createNotice = createNotice,
        _updateNotice = updateNotice,
        _deleteNotice = deleteNotice,
        super(const NoticesState()) {
    on<NoticesLoadRequested>(_onLoad);
    on<NoticesRefreshRequested>(_onLoad);
    on<NoticesLoadMoreRequested>(_onLoadMore);
    on<NoticesFilterChanged>(_onFilterChanged);
    on<NoticesSearchChanged>(_onSearchChanged);
    on<NoticeCreated>(_onCreated);
    on<NoticeUpdated>(_onUpdated);
    on<NoticeDeleted>(_onDeleted);
  }

  final GetNotices _getNotices;
  final GetCachedNotices _getCachedNotices;
  final CreateNotice _createNotice;
  final UpdateNotice _updateNotice;
  final DeleteNotice _deleteNotice;

  Future<void> _onLoad(NoticesEvent event, Emitter<NoticesState> emit) async {
    if (event is NoticesLoadRequested) {
      final cached = _getCachedNotices();
      if (cached.isNotEmpty) {
        emit(state.copyWith(status: NoticesStatus.success, notices: cached));
      } else {
        emit(state.copyWith(status: NoticesStatus.loading, clearError: true));
      }
    }
    final result = await _getNotices(const GetNoticesParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: NoticesStatus.failure,
        errorMessage: failure.message,
      )),
      (notices) => emit(state.copyWith(
        status: NoticesStatus.success,
        notices: notices,
        hasReachedMax: notices.length < AppConstants.pageSize,
        clearError: true,
      )),
    );
  }

  Future<void> _onLoadMore(
    NoticesLoadMoreRequested event,
    Emitter<NoticesState> emit,
  ) async {
    if (state.hasReachedMax || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    final result =
        await _getNotices(GetNoticesParams(offset: state.notices.length));
    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        notices: [...state.notices, ...page],
        isLoadingMore: false,
        hasReachedMax: page.length < AppConstants.pageSize,
      )),
    );
  }

  void _onFilterChanged(NoticesFilterChanged event, Emitter<NoticesState> emit) {
    emit(state.copyWith(category: event.category));
  }

  void _onSearchChanged(NoticesSearchChanged event, Emitter<NoticesState> emit) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onCreated(
    NoticeCreated event,
    Emitter<NoticesState> emit,
  ) async {
    final result = await _createNotice(CreateNoticeParams(
      title: event.title,
      content: event.content,
      category: event.category,
      priority: event.priority,
      department: event.department,
    ));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (created) => emit(state.copyWith(notices: [created, ...state.notices])),
    );
  }

  Future<void> _onUpdated(
    NoticeUpdated event,
    Emitter<NoticesState> emit,
  ) async {
    final result = await _updateNotice(UpdateNoticeParams(
      id: event.id,
      title: event.title,
      content: event.content,
      category: event.category,
      priority: event.priority,
      department: event.department,
    ));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updated) => emit(state.copyWith(
        notices:
            state.notices.map((n) => n.id == updated.id ? updated : n).toList(),
        clearError: true,
      )),
    );
  }

  Future<void> _onDeleted(
    NoticeDeleted event,
    Emitter<NoticesState> emit,
  ) async {
    final previous = state;
    emit(state.copyWith(
      notices: state.notices.where((n) => n.id != event.id).toList(),
    ));
    final result = await _deleteNotice(event.id);
    result.fold(
      (failure) => emit(previous.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }
}
