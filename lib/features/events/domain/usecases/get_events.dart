import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventsParams extends Equatable {
  const GetEventsParams({
    this.category = 'all',
    this.limit = AppConstants.pageSize,
    this.offset = 0,
  });

  final String category;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [category, limit, offset];
}

/// Loads a page of events, optionally filtered by category.
class GetEvents implements UseCase<List<Event>, GetEventsParams> {
  const GetEvents(this._repository);

  final EventRepository _repository;

  @override
  Future<Either<Failure, List<Event>>> call(GetEventsParams params) =>
      _repository.getEvents(
        category: params.category,
        limit: params.limit,
        offset: params.offset,
      );
}

/// Synchronous cached first page for a category (instant first paint).
class GetCachedEvents {
  const GetCachedEvents(this._repository);

  final EventRepository _repository;

  List<Event> call(String category) => _repository.getCachedEvents(category);
}
