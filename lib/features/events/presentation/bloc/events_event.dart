part of 'events_bloc.dart';

sealed class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class EventsLoadRequested extends EventsEvent {
  const EventsLoadRequested();
}

class EventsRefreshRequested extends EventsEvent {
  const EventsRefreshRequested();
}

/// Change the active category filter ('all', 'academic', 'social', 'sports').
class EventsFilterChanged extends EventsEvent {
  const EventsFilterChanged(this.category);
  final String category;

  @override
  List<Object?> get props => [category];
}

/// Admin-only: create an event, optionally with a banner image.
class EventCreated extends EventsEvent {
  const EventCreated({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    this.imageBytes,
    this.imageExt,
  });

  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final Uint8List? imageBytes;
  final String? imageExt;

  @override
  List<Object?> get props =>
      [title, description, date, time, location, category, imageBytes, imageExt];
}

class EventDeleted extends EventsEvent {
  const EventDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
