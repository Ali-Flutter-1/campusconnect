import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_local_data_source.dart';
import '../datasources/event_remote_data_source.dart';

class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._remote, this._local, this._networkInfo);

  final EventRemoteDataSource _remote;
  final EventLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  List<Event> getCachedEvents(String category) => _local.getCached(category);

  @override
  Future<Either<Failure, List<Event>>> getEvents({
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final cat = category ?? 'all';
    if (!await _networkInfo.isConnected) {
      final cached = _local.getCached(cat);
      return offset == 0 && cached.isNotEmpty
          ? Right(cached)
          : const Left(NetworkFailure());
    }
    try {
      final items =
          await _remote.getEvents(category: category, limit: limit, offset: offset);
      if (offset == 0) await _local.cache(cat, items);
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Event>> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String location,
    required String category,
    Uint8List? imageBytes,
    String? imageExt,
  }) =>
      _guard(() => _remote.createEvent(
            title: title,
            description: description,
            date: date,
            time: time,
            location: location,
            category: category,
            imageBytes: imageBytes,
            imageExt: imageExt,
          ));

  @override
  Future<Either<Failure, Event>> updateEvent({
    required String id,
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String location,
    required String category,
  }) =>
      _guard(() => _remote.updateEvent(
            id: id,
            title: title,
            description: description,
            date: date,
            time: time,
            location: location,
            category: category,
          ));

  @override
  Future<Either<Failure, Unit>> deleteEvent(String eventId) => _guard(() async {
        await _remote.deleteEvent(eventId);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
