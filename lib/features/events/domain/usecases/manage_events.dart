import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class CreateEventParams extends Equatable {
  const CreateEventParams({
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

  /// Optional banner image to upload alongside the event.
  final Uint8List? imageBytes;
  final String? imageExt;

  @override
  List<Object?> get props =>
      [title, description, date, time, location, category, imageBytes, imageExt];
}

/// Admin-only: schedules a new event (optionally with a banner image).
class CreateEvent implements UseCase<Event, CreateEventParams> {
  const CreateEvent(this._repository);

  final EventRepository _repository;

  @override
  Future<Either<Failure, Event>> call(CreateEventParams params) =>
      _repository.createEvent(
        title: params.title,
        description: params.description,
        date: params.date,
        time: params.time,
        location: params.location,
        category: params.category,
        imageBytes: params.imageBytes,
        imageExt: params.imageExt,
      );
}

class UpdateEventParams extends Equatable {
  const UpdateEventParams({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String category;

  @override
  List<Object?> get props =>
      [id, title, description, date, time, location, category];
}

/// Admin-only: edits an event.
class UpdateEvent implements UseCase<Event, UpdateEventParams> {
  const UpdateEvent(this._repository);

  final EventRepository _repository;

  @override
  Future<Either<Failure, Event>> call(UpdateEventParams params) =>
      _repository.updateEvent(
        id: params.id,
        title: params.title,
        description: params.description,
        date: params.date,
        time: params.time,
        location: params.location,
        category: params.category,
      );
}

/// Admin-only: removes an event.
class DeleteEvent implements UseCase<Unit, String> {
  const DeleteEvent(this._repository);

  final EventRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String eventId) =>
      _repository.deleteEvent(eventId);
}
