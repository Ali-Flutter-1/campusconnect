part of 'admin_complaints_bloc.dart';

sealed class AdminComplaintsEvent extends Equatable {
  const AdminComplaintsEvent();

  @override
  List<Object?> get props => [];
}

class AdminComplaintsLoadRequested extends AdminComplaintsEvent {
  const AdminComplaintsLoadRequested();
}

class AdminComplaintsRefreshRequested extends AdminComplaintsEvent {
  const AdminComplaintsRefreshRequested();
}

/// Filter by status: 'all', 'open', 'in_progress', 'resolved', 'rejected'.
class AdminComplaintsFilterChanged extends AdminComplaintsEvent {
  const AdminComplaintsFilterChanged(this.filter);
  final String filter;

  @override
  List<Object?> get props => [filter];
}

/// Approve / resolve / reject / reopen a single request.
class AdminComplaintStatusChanged extends AdminComplaintsEvent {
  const AdminComplaintStatusChanged({required this.id, required this.status});

  final String id;
  final String status;

  @override
  List<Object?> get props => [id, status];
}
