part of 'notices_bloc.dart';

sealed class NoticesEvent extends Equatable {
  const NoticesEvent();

  @override
  List<Object?> get props => [];
}

class NoticesLoadRequested extends NoticesEvent {
  const NoticesLoadRequested();
}

class NoticesRefreshRequested extends NoticesEvent {
  const NoticesRefreshRequested();
}

/// Load the next page (infinite scroll).
class NoticesLoadMoreRequested extends NoticesEvent {
  const NoticesLoadMoreRequested();
}

class NoticesFilterChanged extends NoticesEvent {
  const NoticesFilterChanged(this.category);
  final String category;

  @override
  List<Object?> get props => [category];
}

class NoticesSearchChanged extends NoticesEvent {
  const NoticesSearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Admin-only.
class NoticeCreated extends NoticesEvent {
  const NoticeCreated({
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.department,
  });

  final String title;
  final String content;
  final String category;
  final String priority;
  final String? department;

  @override
  List<Object?> get props => [title, content, category, priority, department];
}

/// Admin-only: edit an existing notice.
class NoticeUpdated extends NoticesEvent {
  const NoticeUpdated({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.department,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final String priority;
  final String? department;

  @override
  List<Object?> get props =>
      [id, title, content, category, priority, department];
}

class NoticeDeleted extends NoticesEvent {
  const NoticeDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
