import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source.dart';

class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._remote, this._networkInfo);

  final EventRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<Event>>> getEvents({String? category}) =>
      _guard(() => _remote.getEvents(category: category));

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
