part of 'complaints_bloc.dart';

enum ComplaintsStatus { initial, loading, success, failure }

class ComplaintsState extends Equatable {
  const ComplaintsState({
    this.status = ComplaintsStatus.initial,
    this.complaints = const [],
    this.filter = 'all',
    this.errorMessage,
  });

  final ComplaintsStatus status;
  final List<Complaint> complaints;
  final String filter;
  final String? errorMessage;

  List<Complaint> get filtered => filter == 'all'
      ? complaints
      : complaints.where((c) => c.status == filter).toList();

  int get total => complaints.length;
  int get activeCount => complaints.where((c) => c.isActive).length;
  int get resolvedCount => complaints.where((c) => c.isResolved).length;

  ComplaintsState copyWith({
    ComplaintsStatus? status,
    List<Complaint>? complaints,
    String? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ComplaintsState(
      status: status ?? this.status,
      complaints: complaints ?? this.complaints,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, complaints, filter, errorMessage];
}
