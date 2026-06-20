import 'package:connect/features/events/domain/entities/event.dart';
import 'package:connect/features/events/domain/usecases/get_events.dart';
import 'package:connect/features/events/domain/usecases/manage_events.dart';
import 'package:connect/features/events/presentation/bloc/events_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetEvents extends Mock implements GetEvents {}

class _MockCreateEvent extends Mock implements CreateEvent {}

class _MockDeleteEvent extends Mock implements DeleteEvent {}

void main() {
  late _MockGetEvents getEvents;
  late _MockCreateEvent createEvent;
  late _MockDeleteEvent deleteEvent;

  final event = Event(
    id: 'e1',
    title: 'Tech Talk',
    description: 'AI',
    date: DateTime(2026, 6, 1),
    time: '4 PM',
    location: 'Hall A',
    category: 'academic',
  );

  setUp(() {
    getEvents = _MockGetEvents();
    createEvent = _MockCreateEvent();
    deleteEvent = _MockDeleteEvent();
  });

  EventsBloc build() => EventsBloc(
        getEvents: getEvents,
        createEvent: createEvent,
        deleteEvent: deleteEvent,
      );

  test('load emits loading then success with events', () async {
    when(() => getEvents(any())).thenAnswer((_) async => Right([event]));
    final bloc = build();

    expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<EventsState>((s) => s.status == EventsStatus.loading),
        predicate<EventsState>((s) =>
            s.status == EventsStatus.success && s.events.length == 1),
      ]),
    );

    bloc.add(const EventsLoadRequested());
  });

  test('filter change reloads with the new category', () async {
    when(() => getEvents(any())).thenAnswer((_) async => Right([event]));
    final bloc = build();

    bloc.add(const EventsLoadRequested());
    await bloc.stream.firstWhere((s) => s.status == EventsStatus.success);

    bloc.add(const EventsFilterChanged('sports'));
    final next = await bloc.stream.firstWhere((s) => s.filter == 'sports');
    expect(next.filter, 'sports');
  });
}
