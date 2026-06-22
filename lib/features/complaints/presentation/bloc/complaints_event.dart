part of 'complaints_bloc.dart';

sealed class ComplaintsEvent extends Equatable {
  const ComplaintsEvent();

  @override
  List<Object?> get props => [];
}

class ComplaintsLoadRequested extends ComplaintsEvent {
  const ComplaintsLoadRequested();
}

class ComplaintsRefreshRequested extends ComplaintsEvent {
  const ComplaintsRefreshRequested();
}

/// Filter by status: 'all', 'open', 'in_progress', 'resolved'.
class ComplaintsFilterChanged extends ComplaintsEvent {
  const ComplaintsFilterChanged(this.filter);
  final String filter;

  @override
  List<Object?> get props => [filter];
}

class ComplaintCreated extends ComplaintsEvent {
  const ComplaintCreated({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final String category;

  @override
  List<Object?> get props => [title, description, category];
}
