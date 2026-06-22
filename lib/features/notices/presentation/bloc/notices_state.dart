part of 'notices_bloc.dart';

enum NoticesStatus { initial, loading, success, failure }

class NoticesState extends Equatable {
  const NoticesState({
    this.status = NoticesStatus.initial,
    this.notices = const [],
    this.category = 'all',
    this.query = '',
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final NoticesStatus status;
  final List<Notice> notices;
  final String category;
  final String query;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? errorMessage;

  /// Notices matching the active category + search query.
  List<Notice> get _filtered {
    final q = query.trim().toLowerCase();
    return notices.where((n) {
      final matchesCategory = category == 'all' || n.category == category;
      final matchesQuery = q.isEmpty ||
          n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Notice> get pinned => _filtered.where((n) => n.isPinned).toList();
  List<Notice> get recent => _filtered.where((n) => !n.isPinned).toList();
  bool get isEmpty => _filtered.isEmpty;

  NoticesState copyWith({
    NoticesStatus? status,
    List<Notice>? notices,
    String? category,
    String? query,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NoticesState(
      status: status ?? this.status,
      notices: notices ?? this.notices,
      category: category ?? this.category,
      query: query ?? this.query,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        notices,
        category,
        query,
        hasReachedMax,
        isLoadingMore,
        errorMessage,
      ];
}
