part of 'events_bloc.dart';

enum EventsStatus { initial, loading, success, failure }

class EventsState extends Equatable {
  const EventsState({
    this.status = EventsStatus.initial,
    this.events = const [],
    this.filter = 'all',
    this.errorMessage,
  });

  final EventsStatus status;
  final List<Event> events;
  final String filter;
  final String? errorMessage;

  EventsState copyWith({
    EventsStatus? status,
    List<Event>? events,
    String? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EventsState(
      status: status ?? this.status,
      events: events ?? this.events,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, events, filter, errorMessage];
}
