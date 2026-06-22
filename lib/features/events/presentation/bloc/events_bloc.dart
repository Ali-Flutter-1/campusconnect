import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/get_events.dart';
import '../../domain/usecases/manage_events.dart';

part 'events_event.dart';
part 'events_state.dart';

/// Drives the Events screen: paginated load + category filter and admin
/// create/edit/delete.
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc({
    required GetEvents getEvents,
    required GetCachedEvents getCachedEvents,
    required CreateEvent createEvent,
    required UpdateEvent updateEvent,
    required DeleteEvent deleteEvent,
  })  : _getEvents = getEvents,
        _getCachedEvents = getCachedEvents,
        _createEvent = createEvent,
        _updateEvent = updateEvent,
        _deleteEvent = deleteEvent,
        super(const EventsState()) {
    on<EventsLoadRequested>(_onLoad);
    on<EventsRefreshRequested>(_onRefresh);
    on<EventsLoadMoreRequested>(_onLoadMore);
    on<EventsFilterChanged>(_onFilterChanged);
    on<EventCreated>(_onCreated);
    on<EventUpdated>(_onUpdated);
    on<EventDeleted>(_onDeleted);
  }

  final GetEvents _getEvents;
  final GetCachedEvents _getCachedEvents;
  final CreateEvent _createEvent;
  final UpdateEvent _updateEvent;
  final DeleteEvent _deleteEvent;

  Future<void> _onLoad(
    EventsLoadRequested event,
    Emitter<EventsState> emit,
  ) async {
    final cached = _getCachedEvents(state.filter);
    if (cached.isNotEmpty) {
      emit(state.copyWith(status: EventsStatus.success, events: cached));
    } else {
      emit(state.copyWith(status: EventsStatus.loading, clearError: true));
    }
    await _load(emit);
  }

  Future<void> _onRefresh(
    EventsRefreshRequested event,
    Emitter<EventsState> emit,
  ) =>
      _load(emit);

  Future<void> _onFilterChanged(
    EventsFilterChanged event,
    Emitter<EventsState> emit,
  ) async {
    if (event.category == state.filter) return;
    final cached = _getCachedEvents(event.category);
    emit(state.copyWith(
      filter: event.category,
      status: cached.isNotEmpty ? EventsStatus.success : EventsStatus.loading,
      events: cached,
      hasReachedMax: false,
    ));
    await _load(emit);
  }

  Future<void> _load(Emitter<EventsState> emit) async {
    final result = await _getEvents(GetEventsParams(category: state.filter));
    result.fold(
      (failure) => emit(state.copyWith(
        status: EventsStatus.failure,
        errorMessage: failure.message,
      )),
      (events) => emit(state.copyWith(
        status: EventsStatus.success,
        events: events,
        hasReachedMax: events.length < AppConstants.pageSize,
        clearError: true,
      )),
    );
  }

  Future<void> _onLoadMore(
    EventsLoadMoreRequested event,
    Emitter<EventsState> emit,
  ) async {
    if (state.hasReachedMax || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getEvents(
      GetEventsParams(category: state.filter, offset: state.events.length),
    );
    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        events: [...state.events, ...page],
        isLoadingMore: false,
        hasReachedMax: page.length < AppConstants.pageSize,
      )),
    );
  }

  Future<void> _onCreated(EventCreated event, Emitter<EventsState> emit) async {
    final result = await _createEvent(CreateEventParams(
      title: event.title,
      description: event.description,
      date: event.date,
      time: event.time,
      location: event.location,
      category: event.category,
      imageBytes: event.imageBytes,
      imageExt: event.imageExt,
    ));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const EventsRefreshRequested()),
    );
  }

  Future<void> _onUpdated(EventUpdated event, Emitter<EventsState> emit) async {
    final result = await _updateEvent(UpdateEventParams(
      id: event.id,
      title: event.title,
      description: event.description,
      date: event.date,
      time: event.time,
      location: event.location,
      category: event.category,
    ));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updated) => emit(state.copyWith(
        events:
            state.events.map((e) => e.id == updated.id ? updated : e).toList(),
        clearError: true,
      )),
    );
  }

  Future<void> _onDeleted(EventDeleted event, Emitter<EventsState> emit) async {
    final previous = state;
    emit(state.copyWith(
      events: state.events.where((e) => e.id != event.id).toList(),
    ));
    final result = await _deleteEvent(event.id);
    result.fold(
      (failure) => emit(previous.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }
}
