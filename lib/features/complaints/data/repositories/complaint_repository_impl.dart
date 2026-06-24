import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaint_repository.dart';
import '../datasources/complaint_local_data_source.dart';
import '../datasources/complaint_remote_data_source.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  const ComplaintRepositoryImpl(this._remote, this._local, this._networkInfo);

  final ComplaintRemoteDataSource _remote;
  final ComplaintLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<Complaint>>> getMyComplaints() =>
      _guard(_remote.getMyComplaints);

  @override
  Future<Either<Failure, Complaint>> createComplaint({
    required String title,
    required String description,
    required String category,
  }) =>
      _guard(() => _remote.createComplaint(
            title: title,
            description: description,
            category: category,
          ));

  @override
  List<Complaint> getCachedComplaints() => _local.getCachedAll();

  @override
  Future<Either<Failure, List<Complaint>>> getAllComplaints() async {
    if (!await _networkInfo.isConnected) {
      // Offline: serve the cached queue (if any) rather than erroring.
      final cached = _local.getCachedAll();
      return cached.isNotEmpty ? Right(cached) : const Left(NetworkFailure());
    }
    try {
      final items = await _remote.getAllComplaints();
      await _local.cacheAll(items);
      return Right(items);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Complaint>> updateStatus({
    required String id,
    required String status,
  }) =>
      _guard(() => _remote.updateStatus(id: id, status: status));

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
