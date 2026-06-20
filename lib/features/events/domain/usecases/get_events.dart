import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

/// Loads events, optionally filtered by category.
class GetEvents implements UseCase<List<Event>, String?> {
  const GetEvents(this._repository);

  final EventRepository _repository;

  @override
  Future<Either<Failure, List<Event>>> call(String? category) =>
      _repository.getEvents(category: category);
}
