import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/usecases/complaint_usecases.dart';

part 'admin_complaints_event.dart';
part 'admin_complaints_state.dart';

/// Drives the admin "Approvals" screen: load every submitted request, filter by
/// status, and approve / resolve / reject them. Status changes are applied
/// optimistically and rolled back if the server rejects the update.
class AdminComplaintsBloc
    extends Bloc<AdminComplaintsEvent, AdminComplaintsState> {
  AdminComplaintsBloc({
    required GetAllComplaints getAllComplaints,
    required GetCachedComplaints getCachedComplaints,
    required UpdateComplaintStatus updateStatus,
  })  : _getAllComplaints = getAllComplaints,
        _getCachedComplaints = getCachedComplaints,
        _updateStatus = updateStatus,
        super(const AdminComplaintsState()) {
    on<AdminComplaintsLoadRequested>(_onLoad);
    on<AdminComplaintsRefreshRequested>(_onLoad);
    on<AdminComplaintsFilterChanged>(_onFilterChanged);
    on<AdminComplaintStatusChanged>(_onStatusChanged);
  }

  final GetAllComplaints _getAllComplaints;
  final GetCachedComplaints _getCachedComplaints;
  final UpdateComplaintStatus _updateStatus;

  Future<void> _onLoad(
    AdminComplaintsEvent event,
    Emitter<AdminComplaintsState> emit,
  ) async {
    if (event is AdminComplaintsLoadRequested) {
      // Paint the cached queue instantly, then revalidate from the network.
      final cached = _getCachedComplaints();
      emit(state.copyWith(
        status: cached.isEmpty
            ? AdminComplaintsStatus.loading
            : AdminComplaintsStatus.success,
        complaints: cached.isEmpty ? null : cached,
        clearError: true,
      ));
    }
    final result = await _getAllComplaints(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: AdminComplaintsStatus.failure,
        errorMessage: failure.message,
      )),
      (complaints) => emit(state.copyWith(
        status: AdminComplaintsStatus.success,
        complaints: complaints,
        clearError: true,
      )),
    );
  }

  void _onFilterChanged(
    AdminComplaintsFilterChanged event,
    Emitter<AdminComplaintsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onStatusChanged(
    AdminComplaintStatusChanged event,
    Emitter<AdminComplaintsState> emit,
  ) async {
    final previous = state.complaints;
    // Optimistically reflect the new status.
    emit(state.copyWith(
      complaints: [
        for (final c in previous)
          if (c.id == event.id) c.copyWith(status: event.status) else c,
      ],
      clearError: true,
    ));

    final result = await _updateStatus(
      UpdateComplaintStatusParams(id: event.id, status: event.status),
    );
    result.fold(
      // Roll back to the pre-change list on failure.
      (failure) => emit(state.copyWith(
        complaints: previous,
        errorMessage: failure.message,
      )),
      (_) {},
    );
  }
}
