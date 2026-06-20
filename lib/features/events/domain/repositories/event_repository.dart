import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/event.dart';

/// Contract for reading events, plus admin create/delete.
abstract interface class EventRepository {
  /// All events (soonest first), optionally filtered by [category] ('all' or
  /// null means no filter).
  Future<Either<Failure, List<Event>>> getEvents({String? category});

  // Admin-only.
  Future<Either<Failure, Event>> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String location,
    required String category,
    Uint8List? imageBytes,
    String? imageExt,
  });

  Future<Either<Failure, Unit>> deleteEvent(String eventId);
}
