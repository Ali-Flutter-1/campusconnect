import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/event.dart';
import '../../domain/usecases/get_events.dart';
import '../../domain/usecases/manage_events.dart';

part 'events_event.dart';
part 'events_state.dart';

/// Drives the Events screen: load + category filter and admin create/delete.
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc({
    required GetEvents getEvents,
    required CreateEvent createEvent,
    required DeleteEvent deleteEvent,
  })  : _getEvents = getEvents,
        _createEvent = createEvent,
        _deleteEvent = deleteEvent,
        super(const EventsState()) {
    on<EventsLoadRequested>(_onLoad);
    on<EventsRefreshRequested>(_onRefresh);
    on<EventsFilterChanged>(_onFilterChanged);
    on<EventCreated>(_onCreated);
    on<EventDeleted>(_onDeleted);
  }

  final GetEvents _getEvents;
  final CreateEvent _createEvent;
  final DeleteEvent _deleteEvent;

  Future<void> _onLoad(
    EventsLoadRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(state.copyWith(status: EventsStatus.loading, clearError: true));
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
    emit(state.copyWith(filter: event.category, status: EventsStatus.loading));
    await _load(emit);
  }

  Future<void> _load(Emitter<EventsState> emit) async {
    final result = await _getEvents(state.filter);
    result.fold(
      (failure) => emit(state.copyWith(
        status: EventsStatus.failure,
        errorMessage: failure.message,
      )),
      (events) => emit(state.copyWith(
        status: EventsStatus.success,
        events: events,
        clearError: true,
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
