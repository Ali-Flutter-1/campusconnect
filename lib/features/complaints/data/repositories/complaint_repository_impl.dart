import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaint_repository.dart';
import '../datasources/complaint_remote_data_source.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  const ComplaintRepositoryImpl(this._remote, this._networkInfo);

  final ComplaintRemoteDataSource _remote;
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
