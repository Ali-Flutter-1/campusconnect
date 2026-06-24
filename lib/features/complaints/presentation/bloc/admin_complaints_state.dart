part of 'admin_complaints_bloc.dart';

enum AdminComplaintsStatus { initial, loading, success, failure }

class AdminComplaintsState extends Equatable {
  const AdminComplaintsState({
    this.status = AdminComplaintsStatus.initial,
    this.complaints = const [],
    this.filter = 'all',
    this.errorMessage,
  });

  final AdminComplaintsStatus status;
  final List<Complaint> complaints;
  final String filter;
  final String? errorMessage;

  List<Complaint> get filtered => filter == 'all'
      ? complaints
      : complaints.where((c) => c.status == filter).toList();

  int get total => complaints.length;
  int get pendingCount => complaints.where((c) => c.isActive).length;
  int get resolvedCount => complaints.where((c) => c.isResolved).length;

  AdminComplaintsState copyWith({
    AdminComplaintsStatus? status,
    List<Complaint>? complaints,
    String? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminComplaintsState(
      status: status ?? this.status,
      complaints: complaints ?? this.complaints,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, complaints, filter, errorMessage];
}
