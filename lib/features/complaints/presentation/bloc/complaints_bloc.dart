import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/usecases/complaint_usecases.dart';

part 'complaints_event.dart';
part 'complaints_state.dart';

/// Drives the Complaints/Feedback screen: load the user's submissions, filter by
/// status, and file new ones.
class ComplaintsBloc extends Bloc<ComplaintsEvent, ComplaintsState> {
  ComplaintsBloc({
    required GetMyComplaints getMyComplaints,
    required CreateComplaint createComplaint,
  })  : _getMyComplaints = getMyComplaints,
        _createComplaint = createComplaint,
        super(const ComplaintsState()) {
    on<ComplaintsLoadRequested>(_onLoad);
    on<ComplaintsRefreshRequested>(_onLoad);
    on<ComplaintsFilterChanged>(_onFilterChanged);
    on<ComplaintCreated>(_onCreated);
  }

  final GetMyComplaints _getMyComplaints;
  final CreateComplaint _createComplaint;

  Future<void> _onLoad(
    ComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    if (event is ComplaintsLoadRequested) {
      emit(state.copyWith(status: ComplaintsStatus.loading, clearError: true));
    }
    final result = await _getMyComplaints(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: ComplaintsStatus.failure,
        errorMessage: failure.message,
      )),
      (complaints) => emit(state.copyWith(
        status: ComplaintsStatus.success,
        complaints: complaints,
        clearError: true,
      )),
    );
  }

  void _onFilterChanged(
    ComplaintsFilterChanged event,
    Emitter<ComplaintsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onCreated(
    ComplaintCreated event,
    Emitter<ComplaintsState> emit,
  ) async {
    final result = await _createComplaint(CreateComplaintParams(
      title: event.title,
      description: event.description,
      category: event.category,
    ));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (created) =>
          emit(state.copyWith(complaints: [created, ...state.complaints])),
    );
  }
}
